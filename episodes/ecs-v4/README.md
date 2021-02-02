## ECS-V4: Observability with Sidecars in Kubernetes

We've seen observability with logging, monitoring and tracing. They all have a common requirement - your containers needs certain behaviour, which you need to configure in your image or in your application source code. It's not always possible to mandate that behaviour for every component, so in this episode we'll lookubectl at adding it using sidecars, auxiliary containers which run alongside your application container.

Not every container platform supports sidecars, so we'll focus on Kubernetes which lets you run multiple containers in a Pod. Those containers share the same networkubectl space, and they can also share filesystem directories and even processes. That's how you can add features to an application container without changing the app, and we'll see how that works with logging, monitoring and distributed tracing.

> Here it is on YouTube - [ECS-V4: Observability with Sidecars in Kubernetes](https://youtu.be/YXMwSt4uvHo)

## Links

- [Envoy Jaeger demo](https://github.com/envoyproxy/envoy/tree/main/examples/jaeger-tracing)

## Setup

_Deploy the ingress controller:_

```
kubectl apply -f ./setup/ingress-controller/
```

> Add `widgetario.local` to resolve to `127.0.0.1` in your local `hosts` file

## Demo 1: Logging with a sidecar relay

_Deploy the EFK stack:_

```
kubectl apply -f ./demo1/logging/
```

> Browse to Kibana at http://localhost:5602

No logging pattern for apps - no logs yet.

_Run the Widgetario app:_

```
kubectl apply -f ./demo1/widgetario/
```

> Browse at http://widgetario.local

Refresh Kibana - add `apps` index pattern. Logs there for the DB and APIs but not the website.

_Check the logs in the Pod and in the container filesystem:_

```
kubectl logs -l app=web

kubectl exec deploy/web -- cat /logs/app.log
```

Deploy the [updated Pod spec](demo1/widgetario/update/web.yaml) - using a sidecar container to relay logs, from a shared volume.

```
kubectl apply -f ./demo1/widgetario/update/

kubectl logs -l app=web

kubectl logs -l app=web -c logger
```

> Refresh Kibana and filter for the web logs

## Demo 2: Monitoring with an exporter

_Deploy Prometheus:_

```
kubectl apply -f ./demo2/prometheus/
```

> Configuration adds all Pods in the default namespace; check at:

http://localhost:9091/targets

http://localhost:9091/graph - `app_info`

Deploy the [updated Postgres Pod spec](demo2/widgetario/update/products-db.yaml) - using an exporter sidecar.

_Update Postgres:_

```
kubectl apply -f ./demo2/widgetario/update/

kubectl describe pod -l app=products-db
```

http://localhost:9091/targets

> Now lots of `pg_` metrics, plus `process_cpu_seconds_total` includes the database

## Demo 3: Tracing with the Jaeger sidecar

_Deploy Jaeger:_

```
kubectl apply -f ./demo3/jaeger/operator/

kubectl apply -f ./demo3/jaeger/
```

> Browse to http://localhost - only service reporting traces is `jaeger-query`

The demo app is a simple [Python web server](demo3/envoy-demo/src/service1/service.py). It doesn't use a Jaeger client library, but it propogates tracing headers if it finds them.

_Deploy the demo app from Envoy examples:_

```
kubectl apply -f demo3/envoy-demo/

curl -v localhost:8000/svc/1
```

Direct communication from service 1 to 2 - see [service 1 Pod spec](episodes/ecs-v4/demo3/envoy-demo/service1.yaml).

The update uses Envoy as a [front proxy](demo3/envoy-demo/src/front-proxy/front-envoy-jaeger.yaml) to generate the initial request ID; then runs Envoy sidecars for [service 1](demo3/envoy-demo/update/service1.yaml) and [service 2](demo3/envoy-demo/update/service2.yaml). The sidecars report traces to Jaeger.

_Deploy the update:_

```
kubectl apply -f demo3/envoy-demo/update/

curl localhost:8800/svc/1
```

Same Docker images, config now routes call through Envoy, which sends traces to Jaeger.

> Check Jaeger UI

### Coming next

* ECS-M1: Into the Service Mesh