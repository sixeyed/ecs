## ECS-M2: Service Mesh with Linkerd on Kubernetes

Linkerd is the original service mesh for Kubernetes. It has all the features we looked at last week and it's easy to get started with. This week we'll see how to deploy Linkerd and use it to manage the communication in a sample app. We'll have Linkerd automatically register components into the mesh and use it to control traffic flow, add security and power observability.

Linkerd is a CNCF project with an active community, and a commercially-supported offering. It's solid and fast, and it's used by some pretty big companies - like eBay, Strava and Walmart.

> Here it is on YouTube - [ECS-M2: Service Mesh with Linkerd on Kubernetes](https://youtu.be/kH_ah8utAdM)

### Links

* [Managing Apps on Kubernetes with Istio](https://pluralsight.pxf.io/Rrr3a) - my Pluralsight course

* [ECS-M1: Observability with Sidecars in Kubernetes](https://eltons.show/ecs-m1) - intro to Service Meshes

* [Docker for .NET Apps](https://docker4.net/udemy) - back to container basics with my Udemy course :)

* [Linkerd](https://linkerd.io)

* [Deploying and upgrading Linkerd using Argo CD](https://linkerd.io/2/tasks/gitops/)

* [ECS-C3: GitOps with Kubernetes and Argo](https://eltons.show/episodes/ecs-c3/)

### Pre-reqs

[Docker Desktop](https://www.docker.com/products/docker-desktop) with Kubernetes enabled - or any other Kubernetes deployment.

[Linkerd CLI](https://linkerd.io/2/getting-started/#step-1-install-the-cli).

_Install the Linkerd CLI:_

```
# Windows:
choco install linkerd2

# Mac:
brew install linkerd

# Linux:
curl -sL https://run.linkerd.io/install | sh
```

### Demo 1 - Deploy Linkerd to Kubernetes

Linkerd deploys the control plane as standard Kubernetes resources.

_Verify your Linkerd CLI & Kubernetes cluster:_

```
linkerd version

kubectl get nodes

linkerd check --pre
```

_Generate the deployment manifest:_

```
linkerd install > demo1/linkerd.yaml
```

That generates [linkerd.yaml](demo1/linkerd.yaml).

> It's 3.5K lines of YAML - which is why you need the CLI :)

_Deploy and verify:_

```
kubectl apply -f demo1/linkerd.yaml

kubectl get ns

kubectl get all -n linkerd

linkerd check
```

> These components are all part of the [control plane](https://linkerd.io/2/reference/architecture/#control-plane). 

_Check the UI:_

```
kubectl get svc linkerd-web -n linkerd

# run this in a new terminal to expose the UI:
linkerd dashboard
```

### Demo 2 - Deploy the Widgetario app

The demo app will run in its own namespace. The initial deployment doesn't mesh the services.

_Deploy without registering to the mesh:_

```
kubectl apply -f demo2/widgetario/

kubectl get all -n widgetario
```

Try the app at http://localhost:8010 

> Check the Linkerd UI - none of the components are meshed.

You can configure automatic mesh registration for Pods, Deployments and whole namespaces. 

The updated [01-namespace.yaml](demo2/widgetario/update1/01-namespace.yaml) adds the Linkerd annotation.

_Set the namespace for automatic proxy injection:_

```
kubectl get pods -n widgetario

kubectl apply -f demo2/widgetario/update1/

kubectl get pods -n widgetario
```

> Nothing. Automatic injection is via an [admission webhooks](https://kubernetes.io/docs/reference/access-authn-authz/extensible-admission-controllers/#admission-webhooks) - it doesn't fire on existing Pods.

The updated Deployment specs [update2/products-api.yaml](demo2/widgetario/update2/products-api.yaml) add the annotation at the Pod level - that's a rollout so the new Pods will be registered with the mesh.

_Try again:_

```
kubectl apply -f demo2/widgetario/update2/

kubectl get pods -n widgetario
```

> The web Pod has an extra [debug sidecar](https://linkerd.io/2/tasks/using-the-debug-container/), configured in [update2/web.yaml](demo2/widgetario/update2/web.yaml)

Check the Linkerd dashboard:

- [namespaces/widgetario](http://localhost:50750/namespaces/widgetario) shows the live service map

- [deployments/web](http://localhost:50750/namespaces/widgetario/deployments/web) - shows the traffic flow for the web component

### Demo 3 - Test security with mTLS

Mutual TLS is applied between meshed services *by default*. Linkerd manages the TLS certs, applying them in the proxy sidecar.

_Check the traffic from the web Pod to the stock API Pod:_

```
# grab the IP of the API Pod:
kubectl get po -n widgetario -l app=stock-api -o wide

kubectl exec deploy/web -n widgetario -it -c linkerd-debug -- sh

curl http://stock-api/stock/1

# insert Pod IP address:
tshark -i any -d tcp.port==80,ssl | grep <pod-ip>
```

> The debug container is super useful in non-production environments

TLS is optional in the current Linkerd (2.9). Meshed services are upgraded to mTLS automatically. Non-meshed services can consume meshed services over plain HTTP.

_Verify that a non-meshed Pod can use the stock API:_

```
kubectl apply -f ./demo2/sleep.yaml

kubectl exec pod/sleep -n default -it -- sh

nslookup stock-api.widgetario.svc.cluster.local

wget -qO- stock-api.widgetario.svc.cluster.local/stock/1
```
> Optionally enforcing mTLS is planned for a future release - as is authz, [provide Service-to-Service authorization](https://github.com/linkerd/linkerd2/issues/3342)


### Demo 4 - Traffic split for backend APIs

Traffic management in Linkerd uses the [Traffic Split spec](https://github.com/servicemeshinterface/smi-spec/blob/main/apis/traffic-split/v1alpha1/traffic-split.md) from the Service Mesh Interface.

You can manage traffic for a canary deployment with multiple Kubernetes Services:

- the _root service_ is the domain the consumer uses, e.g. `products-api`
- the _backend services_ are the targets for the traffic split.

[products-api-services.yaml](demo4/widgetario/products-api-services.yaml) defines all those services and [100-0.yaml](demo4/widgetario/traffic-split/100-0.yaml) defines a split which sends all traffic to the existing v1 service.

_Deploy the traffic split - the app behaviour is the same:_

```
kubectl apply -f ./demo4/widgetario/products-api-services.yaml

kubectl apply -f ./demo4/widgetario/traffic-split/100-0.yaml
```

Try the app at http://localhost:8010 - same output, same set of Pods

[products-api-v2.yaml](demo4/widgetario/products-api-v2.yaml) deploys a new version of the products API with a price inflation, and [70-30.yaml](demo4/widgetario/traffic-split/70-30.yaml) sends it 30% of traffic.

_Deploy the v2 API and shift the traffic:_

```
kubectl apply -f ./demo4/widgetario/products-api-v2.yaml

kubectl apply -f ./demo4/widgetario/traffic-split/70-30.yaml
```

- Try localhost:8010 & refresh; now ~1/3 calls have the higher prices.

- Check the traffic split in the Linkerd UI http://localhost:50750/namespaces/widgetario/trafficsplits

> You get finer-grained traffic management with [Service Profiles](https://linkerd.io/2/reference/service-profiles/) - a custom resource which changes behaviour for a target Kubernetes Service. Features include per-route monitoring, retries and timeouts.

> You can also add Linkerd functionality to incoming external traffic, [configuring your ingress controller](https://linkerd.io/2/tasks/using-ingress/). Then you can apply profiles and traffic splits to the entrypoint of your app - e.g. the web component in the Widgetario app.

### Demo 5 - Observability

The Linkerd UI gives you a useful overview of the mesh, with Grafana dashboards showing the metrics it collects. 

You can drill down into more detail using the [Linkerd CLI](https://linkerd.io/2/reference/cli/).

_Print some of the details about meshed services:_

```
linkerd stat ts/products-api-canary -n widgetario

linkerd edges po -n widgetario
```

You can also monitor the real-time network communication between components.

_Tap the calls from the web app to the stock API:_

```
linkerd tap deploy/web --to deploy/stock-api -n widgetario
```

Browse & refresh the site to see the wire tap.

> You can also integrate Linkerd with Jaeger, see [Distributed tracing with Linkerd](https://linkerd.io/2/tasks/distributed-tracing/)

### Coming next

* ECS-M3: Service Mesh with Istio on Kubernetes
