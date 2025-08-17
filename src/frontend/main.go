// Copyright 2018 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// ...

package main

import (
	"context"
	"fmt"
	"net/http"
	"os"
	"time"

	"cloud.google.com/go/profiler"
	"github.com/gorilla/mux"
	"github.com/pkg/errors"
	"github.com/sirupsen/logrus"
	"go.opentelemetry.io/contrib/instrumentation/google.golang.org/grpc/otelgrpc"
	"go.opentelemetry.io/contrib/instrumentation/net/http/otelhttp"
	"go.opentelemetry.io/otel"
	"go.opentelemetry.io/otel/exporters/otlp/otlptrace/otlptracegrpc"
	"go.opentelemetry.io/otel/propagation"
	sdktrace "go.opentelemetry.io/otel/sdk/trace"
	"google.golang.org/grpc"

	// << ADDED PROMETHEUS IMPORTS >>
	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promhttp"
	"strconv"
)

// << EXISTING CONSTS AND VARS >>
const (
	port            = "8080"
	defaultCurrency = "USD"
	cookieMaxAge    = 60 * 60 * 48

	cookiePrefix    = "shop_"
	cookieSessionID = cookiePrefix + "session-id"
	cookieCurrency  = cookiePrefix + "currency"
)

var (
	whitelistedCurrencies = map[string]bool{
		"USD": true,
		"EUR": true,
		"CAD": true,
		"JPY": true,
		"GBP": true,
		"TRY": true,
	}

	baseUrl         = ""

	// << PROMETHEUS METRICS >>
	requestCount = prometheus.NewCounterVec(
		prometheus.CounterOpts{
			Name: "frontend_requests_total",
			Help: "Total HTTP requests processed",
		},
		[]string{"handler", "method", "status"},
	)

	requestDuration = prometheus.NewHistogramVec(
		prometheus.HistogramOpts{
			Name:    "frontend_request_duration_seconds",
			Help:    "Duration of HTTP requests",
			Buckets: prometheus.DefBuckets,
		},
		[]string{"handler"},
	)
)

func init() {
	prometheus.MustRegister(requestCount, requestDuration)
}

// << EXISTING TYPES >>
type ctxKeySessionID struct{}

type frontendServer struct {
	productCatalogSvcAddr string
	productCatalogSvcConn *grpc.ClientConn

	currencySvcAddr string
	currencySvcConn *grpc.ClientConn

	cartSvcAddr string
	cartSvcConn *grpc.ClientConn

	recommendationSvcAddr string
	recommendationSvcConn *grpc.ClientConn

	checkoutSvcAddr string
	checkoutSvcConn *grpc.ClientConn

	shippingSvcAddr string
	shippingSvcConn *grpc.ClientConn

	adSvcAddr string
	adSvcConn *grpc.ClientConn

	collectorAddr *string
	collectorConn *grpc.ClientConn

	shoppingAssistantSvcAddr string
}

// << PROMETHEUS WRAPPER FUNCTION >>
type statusRecorder struct {
	http.ResponseWriter
	status int
}

func (r *statusRecorder) WriteHeader(code int) {
	r.status = code
	r.ResponseWriter.WriteHeader(code)
}

func instrumentHandler(name string, h http.HandlerFunc) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		rec := &statusRecorder{ResponseWriter: w, status: 200}
		start := time.Now()
		h(rec, r)
		duration := time.Since(start).Seconds()

		requestCount.WithLabelValues(name, r.Method, strconv.Itoa(rec.status)).Inc()
		requestDuration.WithLabelValues(name).Observe(duration)
	}
}

func registerMetricsEndpoint(mux *http.ServeMux) {
	mux.Handle("/metrics", promhttp.Handler())
}

// << MAIN FUNCTION WITH PROMETHEUS INTEGRATION >>
func main() {
	ctx := context.Background()
	log := logrus.New()
	log.Level = logrus.DebugLevel
	log.Formatter = &logrus.JSONFormatter{
		FieldMap: logrus.FieldMap{
			logrus.FieldKeyTime:  "timestamp",
			logrus.FieldKeyLevel: "severity",
			logrus.FieldKeyMsg:   "message",
		},
		TimestampFormat: time.RFC3339Nano,
	}
	log.Out = os.Stdout

	svc := new(frontendServer)

	otel.SetTextMapPropagator(
		propagation.NewCompositeTextMapPropagator(
			propagation.TraceContext{}, propagation.Baggage{}))

	baseUrl = os.Getenv("BASE_URL")

	if os.Getenv("ENABLE_TRACING") == "1" {
		log.Info("Tracing enabled.")
		initTracing(log, ctx, svc)
	} else {
		log.Info("Tracing disabled.")
	}

	if os.Getenv("ENABLE_PROFILER") == "1" {
		log.Info("Profiling enabled.")
		go initProfiling(log, "frontend", "1.0.0")
	} else {
		log.Info("Profiling disabled.")
	}

	srvPort := port
	if os.Getenv("PORT") != "" {
		srvPort = os.Getenv("PORT")
	}
	addr := os.Getenv("LISTEN_ADDR")
	mustMapEnv(&svc.productCatalogSvcAddr, "PRODUCT_CATALOG_SERVICE_ADDR")
	mustMapEnv(&svc.currencySvcAddr, "CURRENCY_SERVICE_ADDR")
	mustMapEnv(&svc.cartSvcAddr, "CART_SERVICE_ADDR")
	mustMapEnv(&svc.recommendationSvcAddr, "RECOMMENDATION_SERVICE_ADDR")
	mustMapEnv(&svc.checkoutSvcAddr, "CHECKOUT_SERVICE_ADDR")
	mustMapEnv(&svc.shippingSvcAddr, "SHIPPING_SERVICE_ADDR")
	mustMapEnv(&svc.adSvcAddr, "AD_SERVICE_ADDR")
	mustMapEnv(&svc.shoppingAssistantSvcAddr, "SHOPPING_ASSISTANT_SERVICE_ADDR")

	mustConnGRPC(ctx, &svc.currencySvcConn, svc.currencySvcAddr)
	mustConnGRPC(ctx, &svc.productCatalogSvcConn, svc.productCatalogSvcAddr)
	mustConnGRPC(ctx, &svc.cartSvcConn, svc.cartSvcAddr)
	mustConnGRPC(ctx, &svc.recommendationSvcConn, svc.recommendationSvcAddr)
	mustConnGRPC(ctx, &svc.shippingSvcConn, svc.shippingSvcAddr)
	mustConnGRPC(ctx, &svc.checkoutSvcConn, svc.checkoutSvcAddr)
	mustConnGRPC(ctx, &svc.adSvcConn, svc.adSvcAddr)

	r := mux.NewRouter()

	// << WRAPPED ROUTES WITH PROMETHEUS >>
	r.HandleFunc(baseUrl + "/", instrumentHandler("home", svc.homeHandler)).Methods(http.MethodGet, http.MethodHead)
	r.HandleFunc(baseUrl + "/product/{id}", instrumentHandler("product", svc.productHandler)).Methods(http.MethodGet, http.MethodHead)
	r.HandleFunc(baseUrl + "/cart", instrumentHandler("viewCart", svc.viewCartHandler)).Methods(http.MethodGet, http.MethodHead)
	r.HandleFunc(baseUrl + "/cart", instrumentHandler("addToCart", svc.addToCartHandler)).Methods(http.MethodPost)
	r.HandleFunc(baseUrl + "/cart/empty", instrumentHandler("emptyCart", svc.emptyCartHandler)).Methods(http.MethodPost)
	r.HandleFunc(baseUrl + "/setCurrency", instrumentHandler("setCurrency", svc.setCurrencyHandler)).Methods(http.MethodPost)
	r.HandleFunc(baseUrl + "/logout", instrumentHandler("logout", svc.logoutHandler)).Methods(http.MethodGet)
	r.HandleFunc(baseUrl + "/cart/checkout", instrumentHandler("placeOrder", svc.placeOrderHandler)).Methods(http.MethodPost)
	r.HandleFunc(baseUrl + "/assistant", instrumentHandler("assistant", svc.assistantHandler)).Methods(http.MethodGet)
	r.PathPrefix(baseUrl + "/static/").Handler(http.StripPrefix(baseUrl+"/static/", http.FileServer(http.Dir("./static/"))))
	r.HandleFunc(baseUrl + "/robots.txt", func(w http.ResponseWriter, _ *http.Request) { fmt.Fprint(w, "User-agent: *\nDisallow: /") })
	r.HandleFunc(baseUrl + "/_healthz", func(w http.ResponseWriter, _ *http.Request) { fmt.Fprint(w, "ok") })
	r.HandleFunc(baseUrl + "/product-meta/{ids}", instrumentHandler("getProductByID", svc.getProductByID)).Methods(http.MethodGet)
	r.HandleFunc(baseUrl+"/bot", instrumentHandler("chatBot", svc.chatBotHandler)).Methods(http.MethodPost)

	// << PROMETHEUS METRICS ENDPOINT >>
	registerMetricsEndpoint(http.DefaultServeMux)

	var handler http.Handler = r
	handler = &logHandler{log: log, next: handler}     // add logging
	handler = ensureSessionID(handler)                 // add session ID
	handler = otelhttp.NewHandler(handler, "frontend") // add OTel tracing

	log.Infof("starting server on " + addr + ":" + srvPort)
	log.Fatal(http.ListenAndServe(addr+":"+srvPort, handler))
}

// << EXISTING FUNCTIONS: initStats, initTracing, initProfiling, mustMapEnv, mustConnGRPC >>
