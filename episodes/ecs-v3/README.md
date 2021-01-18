## ECS-V3: Distributed Tracing with Jaeger and Kubernetes

Distributed tracing records network communication between application components. You add code to your components to identify the transactions you want to trace, using a client library which sends details to a tracing collector. The collector stores sample data and ties together transactions which span multiple components - so you can visualize the  communication in a user flow.

Jaeger is a CNCF project for which supports the OpenTracing standard. You run Jaeger collectors in containers, and scale the tracing components with a message queue and a separate data store. The Jaeger UI shows you the traffic in your app, giving you an overview of how your components connect, and letting you drill down to see durations for different parts of a transaction.

In this episode we'll walk through the dev work you need to add tracing to your app, how you run Jaeger in a simple environment and how you run it in production with Kubernetes.

> Here it is on YouTube - [ECS-V3: Distributed Tracing with Jaeger and Kubernetes](https://youtu.be/FikF0DtxZno)

### Links


### Pre-reqs

[Docker Desktop](https://www.docker.com/products/docker-desktop) - with Kubernetes enabled (Linux container mode if you're running on Windows).

### Demo 1 

### Demo 2 

### Demo 3

### Teardown

### Coming next

* ECS-V4: Adding Observability with Sidecar Containers