## ECS-V4: Observability with Sidecars in Kubernetes

We've seen observability with logging, monitoring and tracing. They all have a common requirement - your containers needs certain behaviour, which you need to configure in your image or in your application source code. It's not always possible to mandate that behaviour for every component, so in this episode we'll look at adding it using sidecars, auxiliary containers which run alongside your application container.

Not every container platform supports sidecars, so we'll focus on Kubernetes which lets you run multiple containers in a Pod. Those containers share the same network space, and they can also share filesystem directories and even processes. That's how you can add features to an application container without changing the app, and we'll see how that works with logging, monitoring and distributed tracing.

> Here it is on YouTube - [ECS-V4: Observability with Sidecars in Kubernetes](https://youtu.be/YXMwSt4uvHo)

## Setup 

_Deploy the ingress controller:_

```
k apply -f .\setup\ingress-controller\
```

> Add `widgetario.local` to resolve to `127.0.0.1` in your local `hosts` file

## Demo 1: Logging with a sidecar relay

_Deploy the EFK stack:_

```
k apply -f .\demo1\logging\
```

> Browse to Kibana at http://localhost:5602

No logging pattern for apps - no logs yet.

_Run the Widgetario app:_

```
k apply -f .\demo1\widgetario\
```

> Browse at http://widgetario.local

Refresh Kibana - add `apps` index pattern. Logs there for the DB and APIs but not the website.

_Check the logs in the Pod and in the container filesystem:_

```
k logs -l app=web

k exec deploy/web -- cat /logs/app.log
```

Deploy the [updated Pod spec](demo1\widgetario\update\web.yaml) - using a sidecar container to relay logs, from a shared volume.

```
k apply -f .\demo1\widgetario\update\

k logs -l app=web 

k logs -l app=web -c logger
```

> Refresh Kibana and filter for the web logs

## Demo 2: Monitoring with an exporter

_Deploy Prometheus:_

```
k apply -f .\demo2\prometheus\
```

> Configuration adds all Pods in the default namespace; check at:

http://localhost:9091/targets

http://localhost:9091/graph - `app_info`

_Update Postgres with an exporter sidecar:_

```
k apply -f .\demo2\widgetario\update\

k describe pod -l app=products-db
```

http://localhost:9091/targets

> Now lots of `pg_` metrics, plus `process_cpu_seconds_total` includes the database


## Demo 3: Tracing with the Jaeger sidecar

_Deploy Jaeger:_

```
k apply -f .\demo3\jaeger\operator\

k apply -f .\demo3\jaeger\
```

> Browse to http://localhost - only service reporting traces is `jaeger-query`



> TODO - finish up, use custom envoy setup

> See https://github.com/envoyproxy/envoy/tree/main/examples/jaeger-tracing