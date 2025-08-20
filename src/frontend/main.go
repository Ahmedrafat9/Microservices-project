// Copyright 2018 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

package main

import (
    "context"
    "fmt"
    "net/http"
    "os"
    "strconv"
    "time"

    "cloud.google.com/go/profiler"
    "github.com/gorilla/mux"
    "github.com/pkg/errors"
    "github.com/sirupsen/logrus"
    "github.com/prometheus/client_golang/prometheus"
    "github.com/prometheus/client_golang/prometheus/promhttp"

    "go.opentelemetry.io/contrib/instrumentation/google.golang.org/grpc/otelgrpc"
    "go.opentelemetry.io/contrib/instrumentation/net/http/otelhttp"
    "go.opentelemetry.io/otel"
    "go.opentelemetry.io/otel/exporters/otlp/otlptrace/otlptracegrpc"
    "go.opentelemetry.io/otel/propagation"
    sdktrace "go.opentelemetry.io/otel/sdk/trace"

    "google.golang.org/grpc"
)

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

	baseUrl = ""
)

var (
    httpRequestsTotal = prometheus.NewCounterVec(
        prometheus.CounterOpts{
            Name: "frontend_http_requests_total",
            Help: "Total number of HTTP requests",
        },
        []string{"path", "method", "status"},
    )

    httpRequestDuration = prometheus.NewHistogramVec(
        prometheus.HistogramOpts{
            Name:    "frontend_http_request_duration_seconds",
            Help:    "HTTP request duration in seconds",
            Buckets: prometheus.DefBuckets,
        },
        []string{"path", "method", "status"},
    )

    // Additional metrics for better error rate monitoring
    httpErrorsTotal = prometheus.NewCounterVec(
        prometheus.CounterOpts{
            Name: "frontend_http_errors_total",
            Help: "Total number of HTTP errors (4xx and 5xx status codes)",
        },
        []string{"path", "method", "status"},
    )

    httpRequestsInFlight = prometheus.NewGauge(
        prometheus.GaugeOpts{
            Name: "frontend_http_requests_in_flight",
            Help: "Number of HTTP requests currently being served",
        },
    )
)

func init() {
    prometheus.MustRegister(
        httpRequestsTotal,
        httpRequestDuration,
        httpErrorsTotal,
        httpRequestsInFlight,
    )
}

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

	collectorAddr string
	collectorConn *grpc.ClientConn

	shoppingAssistantSvcAddr string
}

// responseWriter wraps http.ResponseWriter to capture status code
type responseWriter struct {
    http.ResponseWriter
    statusCode int
}

func (rw *responseWriter) WriteHeader(code int) {
    rw.statusCode = code
    rw.ResponseWriter.WriteHeader(code)
}

// MetricsMiddleware wraps HTTP handlers to collect metrics for error rate calculation
func MetricsMiddleware(next http.Handler) http.Handler {
    return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        start := time.Now()
        
        // Skip metrics collection for the metrics endpoint itself
        if r.URL.Path == "/metrics" || r.URL.Path == baseUrl+"/metrics" {
            next.ServeHTTP(w, r)
            return
        }
        
        // Increment in-flight requests
        httpRequestsInFlight.Inc()
        defer httpRequestsInFlight.Dec()

        // Create a response writer that captures the status code
        wrapped := &responseWriter{ResponseWriter: w, statusCode: http.StatusOK}
        
        // Call the next handler
        next.ServeHTTP(wrapped, r)
        
        // Calculate duration
        duration := time.Since(start).Seconds()
        
        // Get labels - normalize path for better grouping
        path := normalizePath(r.URL.Path)
        method := r.Method
        status := strconv.Itoa(wrapped.statusCode)
        
        // Record metrics
        httpRequestsTotal.WithLabelValues(path, method, status).Inc()
        httpRequestDuration.WithLabelValues(path, method, status).Observe(duration)
        
        // Record errors (4xx and 5xx status codes)
        if wrapped.statusCode >= 400 {
            httpErrorsTotal.WithLabelValues(path, method, status).Inc()
        }
    })
}

// normalizePath normalizes URL paths to reduce cardinality in metrics
func normalizePath(path string) string {
    // Remove baseUrl prefix if present
    if baseUrl != "" && len(path) > len(baseUrl) && path[:len(baseUrl)] == baseUrl {
        path = path[len(baseUrl):]
    }
    
    // Normalize common patterns
    switch {
    case path == "/" || path == "":
        return "/"
    case path == "/_healthz":
        return "/_healthz"
    case path == "/robots.txt":
        return "/robots.txt"
    case path == "/cart":
        return "/cart"
    case path == "/cart/empty":
        return "/cart/empty"
    case path == "/cart/checkout":
        return "/cart/checkout"
    case path == "/setCurrency":
        return "/setCurrency"
    case path == "/logout":
        return "/logout"
    case path == "/assistant":
        return "/assistant"
    case path == "/bot":
        return "/bot"
    case len(path) > 8 && path[:8] == "/product":
        return "/product/{id}"
    case len(path) > 13 && path[:13] == "/product-meta":
        return "/product-meta/{ids}"
    case len(path) > 7 && path[:7] == "/static":
        return "/static/*"
    default:
        return path
    }
}

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
	r.HandleFunc(baseUrl+"/", svc.homeHandler).Methods(http.MethodGet, http.MethodHead)
	r.HandleFunc(baseUrl+"/product/{id}", svc.productHandler).Methods(http.MethodGet, http.MethodHead)
	r.HandleFunc(baseUrl+"/cart", svc.viewCartHandler).Methods(http.MethodGet, http.MethodHead)
	r.HandleFunc(baseUrl+"/cart", svc.addToCartHandler).Methods(http.MethodPost)
	r.HandleFunc(baseUrl+"/cart/empty", svc.emptyCartHandler).Methods(http.MethodPost)
	r.HandleFunc(baseUrl+"/setCurrency", svc.setCurrencyHandler).Methods(http.MethodPost)
	r.HandleFunc(baseUrl+"/logout", svc.logoutHandler).Methods(http.MethodGet)
	r.HandleFunc(baseUrl+"/cart/checkout", svc.placeOrderHandler).Methods(http.MethodPost)
	r.HandleFunc(baseUrl+"/assistant", svc.assistantHandler).Methods(http.MethodGet)
	r.PathPrefix(baseUrl+"/static/").Handler(http.StripPrefix(baseUrl+"/static/", http.FileServer(http.Dir("./static/"))))
	r.HandleFunc(baseUrl+"/robots.txt", func(w http.ResponseWriter, _ *http.Request) { fmt.Fprint(w, "User-agent: *\nDisallow: /") })
	r.HandleFunc(baseUrl+"/_healthz", func(w http.ResponseWriter, _ *http.Request) { fmt.Fprint(w, "ok") })
	r.HandleFunc(baseUrl+"/product-meta/{ids}", svc.getProductByID).Methods(http.MethodGet)
	r.HandleFunc(baseUrl+"/bot", svc.chatBotHandler).Methods(http.MethodPost)
	r.Handle(baseUrl+"/metrics", promhttp.Handler())

	var handler http.Handler = r
	handler = MetricsMiddleware(handler)               // add metrics collection FIRST
	handler = &logHandler{log: log, next: handler}     // add logging
	handler = ensureSessionID(handler)                 // add session ID
	handler = otelhttp.NewHandler(handler, "frontend") // add OTel tracing

	log.Infof("starting server on " + addr + ":" + srvPort)
	log.Fatal(http.ListenAndServe(addr+":"+srvPort, handler))
}

func initStats(log logrus.FieldLogger) {
	// TODO(arbrown) Implement OpenTelemtry stats
}

func initTracing(log logrus.FieldLogger, ctx context.Context, svc *frontendServer) (*sdktrace.TracerProvider, error) {
	mustMapEnv(&svc.collectorAddr, "COLLECTOR_SERVICE_ADDR")
	mustConnGRPC(ctx, &svc.collectorConn, svc.collectorAddr)
	exporter, err := otlptracegrpc.New(
		ctx,
		otlptracegrpc.WithGRPCConn(svc.collectorConn))
	if err != nil {
		log.Warnf("warn: Failed to create trace exporter: %v", err)
	}
	tp := sdktrace.NewTracerProvider(
		sdktrace.WithBatcher(exporter),
		sdktrace.WithSampler(sdktrace.AlwaysSample()))
	otel.SetTracerProvider(tp)

	return tp, err
}

func initProfiling(log logrus.FieldLogger, service, version string) {
	// TODO(ahmetb) this method is duplicated in other microservices using Go
	// since they are not sharing packages.
	for i := 1; i <= 3; i++ {
		log = log.WithField("retry", i)
		if err := profiler.Start(profiler.Config{
			Service:        service,
			ServiceVersion: version,
			// ProjectID must be set if not running on GCP.
			// ProjectID: "my-project",
		}); err != nil {
			log.Warnf("warn: failed to start profiler: %+v", err)
		} else {
			log.Info("started Stackdriver profiler")
			return
		}
		d := time.Second * 10 * time.Duration(i)
		log.Debugf("sleeping %v to retry initializing Stackdriver profiler", d)
		time.Sleep(d)
	}
	log.Warn("warning: could not initialize Stackdriver profiler after retrying, giving up")
}

func mustMapEnv(target *string, envKey string) {
	v := os.Getenv(envKey)
	if v == "" {
		panic(fmt.Sprintf("environment variable %q not set", envKey))
	}
	*target = v
}

func mustConnGRPC(ctx context.Context, conn **grpc.ClientConn, addr string) {
    var err error
    ctx, cancel := context.WithTimeout(ctx, 3*time.Second)
    defer cancel()

    *conn, err = grpc.NewClient(
        addr,
        grpc.WithInsecure(),
        grpc.WithStatsHandler(otelgrpc.NewClientHandler()),
    )
    if err != nil {
        panic(errors.Wrapf(err, "grpc: failed to connect %s", addr))
    }
}