## ECS-M3: Service Mesh with Istio on Kubernetes

Istio is the most well-known and fully-featured service mesh. It uses Envoy as the network proxy, running as a sidecar container in Kubernetes Pods or as an agent on VMs. Istio layers on security with encryption and authorization, traffic management with routing and fault injection, and observability at multiple levels.

We'll see all of those features in action using the Widgetario demo application, and get a feel for the additional modelling and management Istio adds to your apps.

> Here it is on YouTube - [ECS-M3: Service Mesh with Istio on Kubernetes](https://youtu.be/jhmMaP2L-L4)

### Links

* [Managing Apps on Kubernetes with Istio](https://pluralsight.pxf.io/Rrr3a) - my Pluralsight course

* [ECS-M1: Observability with Sidecars in Kubernetes](https://eltons.show/ecs-m1) - intro to Service Meshes

* [Istio docs](https://istio.io/latest/docs/)

* [Fortio](https://github.com/fortio/fortio/#fortio) - load-testing tool

* [Why IBM doesn’t agree with Google’s Open Usage Commons](https://developer.ibm.com/blogs/istio-google-open-usage-commons/) - IBM's concerns over the governance of Istio

### Pre-reqs

* [Docker Desktop](https://www.docker.com/products/docker-desktop) with Kubernetes enabled - or any other Kubernetes deployment.

* [Enough CPU and memory allocated to Docker](https://istio.io/latest/docs/setup/platform-setup/docker/).

* [Istio CLI](https://istio.io/latest/docs/setup/getting-started/#download).

_Install the Istio CLI:_

```
# Windows:
choco install istioctl

# macOS/Linux:
curl -L https://istio.io/downloadIstio | sh -
```

### Demo 1 - Deploy Istio to Kubernetes

Istio deploys the control plane as standard Kubernetes resources.

_Verify your Istio CLI & Kubernetes cluster:_

```
istioctl version

kubectl get nodes
```

_Install the demo profile:_

```
istioctl install --set profile=demo -y
```

_Check the deployment:_

```
kubectl get ns

kubectl get all -n istio-system
```

> Istio used to have a distributed control plane with multiple components - now the whole control plane runs in [Istiod](https://istio.io/latest/news/releases/1.5.x/announcing-1.5/#introducing-istiod)

Telemetry comes from [addons](https://github.com/istio/istio/tree/release-1.9/samples/addons) - install the whole set (Kiali, Prometheus, Grafana and Jaeger):

_Deploy adds and launch the Kiali UI:_

```
kubectl apply -f demo1/addons/

# repeat if the CRD isn't created before the rest of the resources

kubectl get all -n istio-system

istioctl dashboard kiali
```

### Demo 2 - Deploy the Widgetario app

The demo app will run in its own namespace - [01-namespace.yaml](demo2\widgetario\01-namespace.yaml) includes the Istio auto-injection label.

_Deploy without registering to the mesh:_

```
kubectl apply -f demo2/widgetario/01-namespace.yaml

istioctl analyze .\demo2\widgetario\ -n widgetario
```

```
kubectl apply -f demo2/widgetario/

k get pods -n widgetario

istioctl dashboard kiali
```

> Check the Graph in Kiali, then try the app at http://localhost:8010 

_Run some load into the app:_

```
docker container run --rm `
  --add-host "wiredbrain.local:192.168.2.154" `
  fortio/fortio:1.14.1 `
  load -c 32 -qps 25 -t 30m http://wiredbrain.local:8010/
```

### Demo 3 - Secure service access

Mutual TLS is applied between meshed services *by default*. You can enforce mTLS by using the [strict peer authentication policy](https://istio.io/latest/docs/concepts/security/#peer-authentication).

You can also apply service-to-service authorization. Authentication is outside Istio, using dedicated service accounts for each client component.

[web.yaml](demo3\widgetario\web.yaml) adds an explicit service account for the web component; there are similar updates to the APIs.

_Apply the new service accounts:_

```
k apply -f demo3/widgetario/
```

> Everything still works at http://localhost:8010 

Now 

```
k apply -f demo3/authz/deny-all.yaml

curl http://localhost:8010 

k logs -l app=web -n widgetario --since 1m
```

> App breaks - Istio blocks unauthorized communication at the proxy level

Authz - all to web, web to APIs, APIs to db

- 

```
k apply -f .\demo3\authz\allow\
```



### Demo 4 - Traffic management

- fault injection

- traffic split



### Demo 5 - Observability

- kiali
- grafana
- jaeger

### Coming next

* ECS-M4: Open Service Mesh - the SMI Mesh
