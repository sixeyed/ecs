## ECS-V3: Distributed Tracing with Jaeger and Kubernetes

Distributed tracing records network communication between application components. You add code to your components to identify the transactions you want to trace, using a client library which sends details to a tracing collector. The collector stores sample data and ties together transactions which span multiple components - so you can visualize the  communication in a user flow.

Jaeger is a CNCF project for which supports the OpenTracing standard. You run Jaeger collectors in containers, and scale the tracing components with a message queue and a separate data store. The Jaeger UI shows you the traffic in your app, giving you an overview of how your components connect, and letting you drill down to see durations for different parts of a transaction.

In this episode we'll walk through the dev work you need to add tracing to your app, how you run Jaeger in a simple environment and how you run it in production with Kubernetes.

> Here it is on YouTube - [ECS-V3: Distributed Tracing with Jaeger and Kubernetes](https://youtu.be/FikF0DtxZno)

### Links

* [Docker for .NET Apps](https://docker4.net) - my new Udemy course

* [Jaeger docs](https://www.jaegertracing.io)

* [Jaeger Operator for Kubernetes](https://github.com/jaegertracing/jaeger-operator/)

* [OpenTelemetry](https://opentelemetry.io) - standards for observability

* [Source code for the Widgetario demo app](https://github.com/sixeyed/widgetario)


### Pre-reqs

[Docker Desktop](https://www.docker.com/products/docker-desktop) - with Kubernetes enabled (Linux container mode if you're running on Windows).

### Demo 1 - Jaeger and application tracing 

Jaeger runs as a distributed app itself, but for a simple non-prod environment you can use the all-in-one image on Docker Hub.

We'll run a demo app using Compose - [v1.yml](demo1/v1.yml).

_Run Jaeger on its own to start with:_

```
docker-compose -f demo1/v1.yml up -d jaeger
```

> Browse to the UI at http://localhost:16686

The Jaeger UI component makes requests to the query component, which records tracing information.

_Now run the rest of the app:_

```
docker-compose -f demo1/v1.yml up -d
```

There are two back-end services and a website:

* http://localhost:8081/products
* http://localhost:8082/stock/1
* http://localhost:8080

The web app records tracing information with OpenTelemetry and Jaeger client libraries.

Refresh the Jaeger UI and search for:

- Service: _Widgetario.Web_
- Operation: _Action Widgetario.Web.Controllers.HomeController/Index_

The traces show the client service calls but not dependent services

> Open the system architecture in Jaeger http://localhost:16686/dependencies

Nothing.

### Demo 2 - Distributed tracing

The demo services have code for tracing, it just needs to be enabled with a feature flag.

The [v2.yml](demo2/v2.yml) spec turns on tracing for the APIs.

_Update the deployment to enable distributed tracing:_

```
docker-compose -f demo2/v2.yml up -d
```

> Browse to the app again at http://localhost:8080

> Check the traces in Jaeger at http://localhost:16686

The spans are recorded across the services and you can map out the dependency graph.

You'll see the services could use some caching - [v3.yml](demo2/v3.yml) turns it on for the stock API.

_Update the stock API:_

```
docker-compose -f demo2/v3.yml up -d
```

> Try the app again and check the traces and logs for the stock calls

### Demo 3 - Jaeger and Kubernetes

In production you'll use the [Jaeger Operator](https://github.com/jaegertracing/jaeger-operator/) to deploy to Kubernetes; that requires an ingress controller.

_Deploy an Nginx ingress controller:_

```
kubectl apply -f ./demo3/ingress-controller/

kubectl get all -n ingress-nginx
```

_Deploy the Jaeger Operator:_

```
kubectl apply -f ./demo3/jaeger-operator/crds/

kubectl apply -f ./demo3/jaeger-operator/
```

The Operator creates Jaeger instances when you deploy a custom resource - [jaeger.yaml](demo3/jaeger/jaeger.yaml) is as simple as it gets.

_Create a Jaeger instance:_

```
kubectl apply -f ./demo3/jaeger/

kubectl get all

kubectl get ingress
```

> Browse to http://localhost

It's the standard Jaeger UI - the backend is now distributed in a production configuration.

The demo app works with the same Docker images and app configuration in Kubernetes.

_Deploy the demo app:_

```
kubectl apply -f ./demo3/widgetario/

kubectl get pods

kubectl get ingress
```

> Browse to http://widgetario.local/

Refresh the app a few times, then check the traces in Jaeger at http://localhost

### Teardown

Hit the _Reset Kubernetes_ button in Docker Desktop :)

### Coming next

* ECS-V4: Adding Observability with Sidecar Containers