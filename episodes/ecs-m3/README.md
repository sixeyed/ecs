## ECS-M3: Service Mesh with Istio on Kubernetes

Istio is the most well-known and fully-featured service mesh. It uses Envoy as the network proxy, running as a sidecar container in Kubernetes Pods or as an agent on VMs. 

Istio layers on security with encryption and authorization, traffic management with routing and fault injection, and observability at multiple levels.

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

> Istio used to have a distributed control plane with multiple components - now the whole control plane runs in [Istiod](https://istio.io/latest/news/releases/1.5.x/announcing-1.5/#introducing-istiod).

Telemetry comes from [addons](https://github.com/istio/istio/tree/release-1.9/samples/addons) - install the whole set (Kiali, Prometheus, Grafana and Jaeger):

_Deploy add-ons and launch the Kiali UI:_

```
kubectl apply -f demo1/addons/

# repeat if the CRD isn't created before the rest of the resources

kubectl get all -n istio-system

istioctl dashboard kiali
```

### Demo 2 - Deploy the Widgetario app

The demo app will run in its own namespace - [01-namespace.yaml](demo2/widgetario/01-namespace.yaml) includes the Istio auto-injection label.

_Create the namespace and do an Istio dry-run:_

```
kubectl apply -f demo2/widgetario/01-namespace.yaml

istioctl analyze demo2/widgetario/ -n widgetario
```

_Deploy straight onto the mesh:_

```
kubectl apply -f demo2/widgetario/

kubectl get pods -n widgetario

kubectl describe pod -l app=stock-api -n widgetario

istioctl dashboard kiali
```

> Check the Graph in Kiali, then try the app at http://localhost:8010 

_Run some load into the app:_

```
docker container run --rm `
  fortio/fortio:1.14.1 `
  load -c 32 -qps 25 -t 30m http://host.docker.internal:8010/
```

### Demo 3 - Secure service access

Mutual TLS is applied between meshed services *by default*. You can enforce mTLS by using the [strict peer authentication policy](https://istio.io/latest/docs/concepts/security/#peer-authentication).

You can also apply service-to-service authorization. Authentication is outside Istio, using dedicated service accounts for each client component.

[web.yaml](demo3/widgetario/web.yaml) adds an explicit service account for the web component; there are similar updates to the APIs.

_Apply the new service accounts:_

```
kubectl apply -f demo3/widgetario/
```

> Everything still works at http://localhost:8010 

Now deploy a default deny authorization policy. [deny-all.yaml](demo3/authz/deny-all.yaml) blocks all communication for meshed services in the namespace.

```
kubectl apply -f demo3/authz/deny-all.yaml

curl http://localhost:8010 
```

> App breaks - traffic to the web component is blocked.

We can apply fine-grained authorization for this app:

- [web-allow.yaml](demo3/authz/allow/web-allow.yaml) - the web app allows all incoming HTTP GET requests

- [stock-allow-web.yaml](demo3/authz/allow/stock-allow-web.yaml) - the stock API allows GET requests from the website

- [products-allow-web.yaml](demo3/authz/allow/products-allow-web.yaml) - the products API allows GET requests from the website

- [db-allow-api.yaml](demo3/authz/allow/db-allow-api.yaml) - the database allows TCP traffic on port 5432 from the APIs.

```
kubectl apply -f ./demo3/authz/allow/

curl http://localhost:8010 
```

> It can take a few seconds for the policies to get pushed out to the proxies - but then the app works again.

Any Pods which are not authorized - or not  authenticated - can't access the service. [sleep.yaml](demo3/sleep.yaml) doesn't mount a service account token, so it has no service identity.

```
kubectl apply -f demo3/sleep.yaml

kubectl exec -it sleep -- sh

nslookup stock-api.widgetario.svc.cluster.local

wget -qO- http://stock-api.widgetario.svc.cluster.local/stock/1

exit
```

### Demo 4 - Traffic management

Istio provides a lot of traffic management features, including retries and intelligent client-side load balancing.

Traffic management is specced with two Istio resource types: the [DestinationRule]() and the [VirtualService]().

We'll do a canary deployment for a new version of the products API, starting with:

- [deployment-v2.yaml](demo4\products-api\deployment-v2.yaml) - the new v2 Deployment

- [destination-rule.yaml](demo4\products-api\destination-rule.yaml) - the DestinationRule which defines the target subsets

- [virtual-service.yaml](demo4\products-api\virtual-service.yaml) - the VirtualService which specs the traffic rules

```
kubectl apply -f demo4/products-api/

kubectl get po -l app=products-api -n widgetario -o wide 

kubectl get endpoints products-api -n widgetario
```

> The Kubernetes Service would load-balance between v1 and v2, but Istio is selecting the endpoints based on the Pod label selector in the subset

Traffic management in the VirtualService can be used for canary deployments - [75-25.yaml](demo4/products-api/traffic-split/75-25.yaml) sends 25% of traffic to the new deployment.

_Start the canary rollout:_

```
kubectl apply -f demo4/products-api/traffic-split/75-25.yaml
```

Try the app again - refresh and 1 in 4 responses will have the higher prices. [50-50.yaml](demo4/products-api/traffic-split/50-50.yaml) increases the traffic to v2.

```
kubectl apply -f demo4/products-api/traffic-split/50-50.yaml
```

> Try the app and check the graph in Kiali

Istio can also apply fault injection - useful for testing your apps fail gracefully if they can't reach all their dependencies.

The stock-api folder adds new Istio resources:

- [destination-rule.yaml](demo4\stock-api\destination-rule.yaml) - the DestinationRule which defines the target subsets

- [virtual-service.yaml](demo4\stock-api\virtual-service.yaml) - the VirtualService which specs the traffic rules

- [abort-20-pct.yaml](demo4/stock-api/fault-injection/abort-20-pct.yaml)

_Add 20% failure rate to the API and test the app:_

```
kubectl apply -f ./demo4/stock-api

kubectl apply -f ./demo4/stock-api/fault-injection/abort-20-pct.yaml

curl http://localhost:8010

kubectl logs -n widgetario -l app=web --since 30s --tail 100
```

Fault injection responds with a real network fault - your VirtualService rules can include match filters, so you could add failures for users in your test team.

_Replace the 503 fault with a delay:_

```
kubectl apply -f ./demo4/stock-api/fault-injection/delay-70-pct.yaml
```

Try localhost:8010

> You can also use Istio for ingress - with the custom [Ingress Gateway API](https://istio.io/latest/docs/tasks/traffic-management/ingress/ingress-control/). That lets you apply Istio features to external traffic coming into your apps.

### Demo 5 - Observability

Istio add-ons provide all the observability features.

_Send some load into the app:_

```
docker container run --rm `
  fortio/fortio:1.14.1 `
  load -c 32 -qps 25 -t 30m -timeout 5s http://host.docker.internal:8010/
```

_List the available dashboards and run Kiali again:_

```
istioctl dashboard

istioctl dashboard kiali
```

_Try the more detailed dashboards in Grafana:_

```
istioctl dashboard grafana
```

- mesh dashboard
- control plane dashboard
- service dasboard (mtls)

_And lastly the distributed tracing in Jaeger:_

```
istioctl dashboard  jaeger
```

> You'll see individual traces from the services, but they're not linked. This app doesn't have the HTTP header propagation in code, so Jager can't tie requests together into one transaction.

### Coming next

* ECS-M4: Open Service Mesh - the SMI Mesh
