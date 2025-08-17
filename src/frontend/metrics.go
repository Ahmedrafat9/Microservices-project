package main

import (
    "net/http"
    "strconv"
    "time"

    "github.com/prometheus/client_golang/prometheus"
    "github.com/prometheus/client_golang/prometheus/promhttp"
)

var (
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
        recorder := &statusRecorder{ResponseWriter: w, status: 200}
        start := time.Now()
        h(recorder, r)
        duration := time.Since(start).Seconds()

        requestCount.WithLabelValues(name, r.Method, strconv.Itoa(recorder.status)).Inc()
        requestDuration.WithLabelValues(name).Observe(duration)
    }
}

func registerMetricsEndpoint(mux *http.ServeMux) {
    mux.Handle("/metrics", promhttp.Handler())
}
