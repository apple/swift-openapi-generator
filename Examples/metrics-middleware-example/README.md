# Metrics middleware using Swift Metrics and Swift Prometheus

In this example we'll implement a `ClientMiddleware` and `ServerMiddleware`
that use `swift-metrics` and `swift-prometheus` to collect and emit metrics
respectively.

> **Disclaimer:** This example is deliberately simplified and is intended for illustrative purposes only.

## Overview

This example extends the [hello-world-vapor-server-example](../hello-world-vapor-server-example)
with a new target, `MetricsMiddleware`, which is then used when creating
the `Server`.

The metrics can now be accessed my making a HTTP GET request to `/metrics`.

## Testing

### Running the server and querying the metrics endpoint

First, in one terminal, start the server.

```console
% swift run
```

Then, in another terminal, make some requests:

```console
% xargs -n1 -I% curl "localhost:8080/api/greet?name=%" <<< "Juan Mei Tom Bill Anne Ravi Maria"
{
  "message" : "Hello, Juan!"
}
{
  "message" : "Hello, Mei!"
}
{
  "message" : "Hello, Tom!"
}
{
  "message" : "Hello, Bill!"
}
{
  "message" : "Hello, Anne!"
}
{
  "message" : "Hello, Ravi!"
}
{
  "message" : "Hello, Maria!"
}
```

Now you can query the `/metrics` endpoint of the server:

```console
% curl "localhost:8080/metrics"
# TYPE http_requests_total counter
http_requests_total{method="GET",path="/metrics",status="200"} 1
http_requests_total{method="GET",path="//api/greet",status="200"} 7
# TYPE http_request_duration_seconds histogram
http_request_duration_seconds_bucket{method="GET",path="//api/greet",status="200",le="0.005"} 5
http_request_duration_seconds_bucket{method="GET",path="//api/greet",status="200",le="0.01"} 6
http_request_duration_seconds_bucket{method="GET",path="//api/greet",status="200",le="0.025"} 7
http_request_duration_seconds_bucket{method="GET",path="//api/greet",status="200",le="0.05"} 7
http_request_duration_seconds_bucket{method="GET",path="//api/greet",status="200",le="0.1"} 7
http_request_duration_seconds_bucket{method="GET",path="//api/greet",status="200",le="0.25"} 7
http_request_duration_seconds_bucket{method="GET",path="//api/greet",status="200",le="0.5"} 7
http_request_duration_seconds_bucket{method="GET",path="//api/greet",status="200",le="1.0"} 7
http_request_duration_seconds_bucket{method="GET",path="//api/greet",status="200",le="2.5"} 7
http_request_duration_seconds_bucket{method="GET",path="//api/greet",status="200",le="5.0"} 7
http_request_duration_seconds_bucket{method="GET",path="//api/greet",status="200",le="10.0"} 7
http_request_duration_seconds_bucket{method="GET",path="//api/greet",status="200",le="+Inf"} 7
http_request_duration_seconds_sum{method="GET",path="//api/greet",status="200"} 0.025902709
http_request_duration_seconds_count{method="GET",path="//api/greet",status="200"} 7
http_request_duration_seconds_bucket{method="GET",path="/metrics",status="200",le="0.005"} 1
http_request_duration_seconds_bucket{method="GET",path="/metrics",status="200",le="0.01"} 1
http_request_duration_seconds_bucket{method="GET",path="/metrics",status="200",le="0.025"} 1
http_request_duration_seconds_bucket{method="GET",path="/metrics",status="200",le="0.05"} 1
http_request_duration_seconds_bucket{method="GET",path="/metrics",status="200",le="0.1"} 1
http_request_duration_seconds_bucket{method="GET",path="/metrics",status="200",le="0.25"} 1
http_request_duration_seconds_bucket{method="GET",path="/metrics",status="200",le="0.5"} 1
http_request_duration_seconds_bucket{method="GET",path="/metrics",status="200",le="1.0"} 1
http_request_duration_seconds_bucket{method="GET",path="/metrics",status="200",le="2.5"} 1
http_request_duration_seconds_bucket{method="GET",path="/metrics",status="200",le="5.0"} 1
http_request_duration_seconds_bucket{method="GET",path="/metrics",status="200",le="10.0"} 1
http_request_duration_seconds_bucket{method="GET",path="/metrics",status="200",le="+Inf"} 1
http_request_duration_seconds_sum{method="GET",path="/metrics",status="200"} 0.001705458
http_request_duration_seconds_count{method="GET",path="/metrics",status="200"} 1
# TYPE HelloWorldServer.getGreeting.200 counter
HelloWorldServer.getGreeting.200 7
```

The response contains the Prometheus metrics. You should see `http_requests_total{status="200", path="/api/greet", method="GET"} 7` for the seven requests made in the previous step.

### Visualizing the metrics with Prometheus

We'll use [Compose](https://docs.docker.com/compose) to run a set of containers
to collect and visualize the metrics.

The Compose file defines two services: `api` and `prometheus`. The `api`
service uses an image built using the `Dockerfile` in the current directory.
The `prometheus` service uses a public Prometheus image.

The `prometheus` service is configured using the `prometheus.yml` file in the
current directory. This configures Prometheus to scrape the /metrics endpoint
of the API server every 5 seconds.

Build and run the Compose application. You should see logging in the console
from the API server and Prometheus.

> NOTE: You need to keep this terminal window open for the remaining steps. Pressing Ctrl-C will shut down the application.

```console
% docker compose up
[+] Building 12/122
...
[+] Running 2/0
 ⠿ Container metricsmiddleware-prometheus-1  Created                                                    0.0s
 ⠿ Container metricsmiddleware-api-1         Created                                                    0.0s
...
metricsmiddleware-api-1         | 2023-06-08T14:34:24+0000 notice codes.vapor.application : [Vapor] Server starting on http://0.0.0.0:8080
...
metricsmiddleware-prometheus-1  | ts=2023-06-08T14:34:24.914Z caller=web.go:562 level=info component=web msg="Start listening for connections" address=0.0.0.0:9090
...
```

At this point you can make requests to the server, as before:

```console
% % echo "Juan Mei Tom Bill Anne Ravi Maria" | xargs -n1 -I% curl "localhost:8080/api/greet?name=%"
{
  "message" : "Hello, Juan!"
}
{
  "message" : "Hello, Mei!"
}
{
  "message" : "Hello, Tom!"
}
{
  "message" : "Hello, Bill!"
}
{
  "message" : "Hello, Anne!"
}
{
  "message" : "Hello, Ravi!"
}
{
  "message" : "Hello, Maria!"
}
```

Now open the Prometheus UI in your web browser by visiting [localhost:9090](http://localhost:9090). Click the graph tab and update the query to `http_requests_total`, or use [this pre-canned link](http://localhost:9090/graph?g0.expr=http_requests_total&g0.tab=0&g0.stacked=0&g0.show_exemplars=0&g0.range_input=5m).

You should see the graph showing the seven recent requests.
