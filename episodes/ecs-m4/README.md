## ECS-M4: Service Mesh Interface with Traefik Mesh & Consul

The Service Mesh Interface defines a generic API for service mesh features, so you can configure your app without tying it to a particular mesh. There are several SMI implementations and in this episode we'll work with a couple of options to see how the promise of SMI is delivering.

We'll use Traefik Mesh which takes an alternative, lightweight approach to meshing services. It uses SMI for traffic shaping and access control. Then we'll try the service mesh features in Consul Connect and see how the SMI implementation works (or - not).

> Here it is on YouTube - [ECS-M4: Service Mesh Interface with Traefik Mesh & Consul](https://youtu.be/qe6kLTx2eAo)

> And here are the demo files on GitHub - [sixeyed/ecs](https://github.com/sixeyed/ecs/tree/master/episodes/ecs-m4)

### Links

* [Managing Apps on Kubernetes with Istio](https://pluralsight.pxf.io/Rrr3a) - my Pluralsight course

* [Service Mesh Interface (SMI)](https://smi-spec.io)

* [SMI Spec](https://github.com/servicemeshinterface/smi-spec) - GitHub

* [Open Service Mesh](https://docs.openservicemesh.io) - docs

* [Traefik Mesh](https://doc.traefik.io/traefik-mesh/) - docs

* [Consul Connect](https://www.consul.io/docs/connect) - docs

### Pre-reqs

* [Docker Desktop](https://www.docker.com/products/docker-desktop) with Kubernetes enabled - or any other Kubernetes deployment.

* [Kind](https://kind.sigs.k8s.io)- if you want to use multiple clusters locally.

###  Setup

_Create separate clusters for the Traefik and Consul demos:_

```
kind create cluster --name ecs-m4-1 --config setup/kind-1.yaml

kind create cluster --name ecs-m4-2 --config setup/kind-2.yaml
```

### Demo 1

_Deploy the Widgetario demo app:_

```
kubectl config use-context kind-ecs-m4-1

kubectl apply -k ./demo1/widgetario/overlays/kind-1

kubectl get po -n widgetario
```

> Nothing special here, just the usual app with a NodePort Service - http://localhost:30000/


_Install Traefik Mesh:_

```
helm repo add traefik-mesh https://helm.traefik.io/mesh

helm repo update

helm install mesh -n traefik --create-namespace traefik-mesh/traefik-mesh --version 3.0.6

kubectl get all -n traefik

kubectl get crd
```

Traefik Mesh doesn't add a proxy sidecar to your application Pods - it runs a proxy Pod on every node, and you need to configure your apps to route via the proxy:.

You specify the Traefik Mesh service endpoint `[service].[namespace].traefik.mesh` instead of `[service].[namespace].svc.cluster.local`, e.g:

- [demo1/widgetario/update/web-api.yaml](demo1/widgetario/update/web-api.yaml) does that in the web app config

_Update the web app config:_

```
kubectl apply -f demo1/widgetario/update/web-api.yaml

kubectl rollout restart  -n widgetario deploy/web

kubectl get po -n widgetario --watch

curl http://localhost:30000
```

_Confirm the web app can route API calls through the proxy:_

```
kubectl exec -n widgetario deploy/web -- wget -O- http://stock-api:8080/stock/1

kubectl exec -n widgetario deploy/web -- wget -O- http://stock-api.widgetario.traefik.mesh:8080/stock/1
```

### Demo 2 - Securing access and routing traffic

Traefik supports retries, rate limits and circuit breakers through [Kubernetes annotations](https://doc.traefik.io/traefik-mesh/configuration/#kubernetes-service-annotations). Access control and traffic splitting is configured using SMI.

_Upgrade the mesh to enforce access control:_

```
helm upgrade -n traefik mesh traefik-mesh/traefik-mesh --set acl=true --version 3.0.6

curl http://localhost:30000/ -v
```

> Now the app is broken, the website can't access the APIs

To enforce access control all the components need to be connected via the mesh. These updated secrets will bring all routing via the mesh proxy:

- [demo2/widgetario/secrets/products-api-db.yaml](demo2/widgetario/secrets/products-api-db.yaml)
- [demo2/widgetario/secrets/stock-api-connection.yaml](demo2/widgetario/secrets/stock-api-connection.yaml)

And we need to tell Traefik the traffic type with annotations, e.g:

- [demo2/widgetario/services/products-api.yaml](demo2/widgetario/services/products-api.yaml)
- [demo2/widgetario/services/products-db.yaml](demo2/widgetario/services/products-db.yaml)


_Apply the changes to route via the mesh:_

```
kubectl apply -f ./demo2/widgetario/secrets/ -f ./demo2/widgetario/services/

kubectl rollout restart  -n widgetario deploy/stock-api
kubectl rollout restart  -n widgetario deploy/products-api-v1

kubectl get po -n widgetario --watch

curl http://localhost:30000/ -v
```

> Still broken. The default is to deny all traffic.

You enable access with SMI routes:

- [demo2/routes/http-get-routes.yaml](demo2/routes/http-get-routes.yaml)
- [demo2/routes/postgres-route.yaml](demo2/routes/postgres-route.yaml)

And targets:

- [demo2/targets/api-allow-web.yaml](demo2/targets/api-allow-web.yaml)
- [demo2/targets/db-allow-api.yaml](demo2/targets/db-allow-api.yaml)

_Deploy the access control resources:_

```
kubectl apply -f ./demo2/routes/ -f ./demo2/targets/

# shouldn't be necessary - but caching?
kubectl rollout restart  -n widgetario deploy/stock-api
kubectl rollout restart  -n widgetario deploy/products-api-v1
kubectl rollout restart  -n widgetario deploy/web

curl http://localhost:30000/
```

> Now the app works again. Any clients outside of the mesh or without ACL cannot access services.

Traffic splitting is with SMI too - we can deploy an updated products API and shift 30% traffic to it:

- [demo2/widgetario/update/products-api-services.yaml](demo2/widgetario/update/products-api-services.yaml)
- [demo2/widgetario/update/products-api-v2.yaml](demo2/widgetario/update/products-api-v2.yaml)
- [demo2/traffic-split/70-30.yaml](demo2/traffic-split/70-30.yaml)

There's no need for additional ACLs, because that's controlled at the ServiceAccount level, and the new API Deployment uses the same ServiceAcccount.

_Add the traffic split:_

```
kubectl apply -f ./demo2/widgetario/update

kubectl apply -f ./demo2/traffic-split/70-30.yaml
```

> http://localhost:30000/ & refresh

## Demo 3 - migrating to Consul Connect

Traefik Mesh is simple but is missing some features - mTLS is an important one. All the traffic is modelled with SMI for our app, so we should be able to switch to a different implementation easily...

We'll try Consul Connect in a new cluster - starting with the same basic app:

```
kubectl config use-context kind-ecs-m4-2

kubectl apply -k ./demo1/widgetario/overlays/kind-2

kubectl get po -n widgetario --watch
```

> Try the app at http://localhost:31000/

Consul Connect has a Helm chart on Hashicorp's repo. This is the configuration we'll use:

- [demo3/consul/values.yaml](demo3/consul/values.yaml)

This sets up proxy injection into configured Pods.

_Deploy Consul:_

```
helm repo add hashicorp https://helm.releases.hashicorp.com

helm repo update

helm install -f demo3/consul/values.yaml -n hashicorp --create-namespace consul hashicorp/consul --version 0.30.0

kubectl get all -n hashicorp

kubectl get crds

```

> No SMI... Check the Consul UI http://localhost:31100


You can automatically onboard services to the mesh, but you'll typically need additional config. These Deployments are annotated with the Consul setup:

- [demo3/widgetario/deployments/products-api.yaml](demo3/widgetario/deployments/products-api.yaml)
- [demo3/widgetario/deployments/products-db.yaml](demo3/widgetario/deployments/products-db.yaml)
- [demo3/widgetario/deployments/web.yaml](demo3/widgetario/deployments/web.yaml)

To route upstream calls through Consul, you need to explicitly use the local ports, e.g:

- [demo3/widgetario/secrets/products-api-db.yaml](demo3/widgetario/secrets/products-api-db.yaml)
- [demo3/widgetario/secrets/web-api.yaml](demo3/widgetario/secrets/web-api.yaml)

```
kubectl apply -f ./demo3/widgetario/secrets  -f ./demo3/widgetario/deployments

kubectl get po -n widgetario --watch
```

> Proxy sidecars in the Pod - see the service list in Consul http://localhost:31100 & the app http://localhost:31000

Now the app is routing through the mesh, can we configure access control and traffic splitting with SMI resources?

Kinda... There's a separate [Consul SMI controller](https://github.com/hashicorp/consul-smi-controller) project, but it looks like a prototype stage and hasn't been updated for two years.

So we can rely on that, or we could model access control with custom Consul resources - _intentions_:

- [demo3/intentions/allow-api-to-db.yaml](demo3/intentions/allow-api-to-db.yaml)
- [demo3/intentions/allow-web-to-api.yaml](demo3/intentions/allow-web-to-api.yaml)


```
kubectl apply -f ./demo3/intentions

kubectl get po -n widgetario --watch
```

And traffic management with splitters:

- [demo3/splitters/70-30.yaml](demo3/splitters/70-30.yaml)


```
kubectl apply -f ./demo3/widgetario/update/

kubectl apply -f ./demo3/splitters/
```

> Try at http://localhost:31100


### Guidance :)

- I want to like SMI, but I'm not sure it's living up to expectations 
- OSM still pretty early, couldn't get ACL working with Postgres

---

- Main choices: Istio, Linkerd & Consul
- If you're already using the Hashicorp stack -> Consul
- Else if your Kubernetes is strong and the governance issues don't worry you -> Istio
- Else -> Linkerd

---

- Don't spend too much time with the demo projects, get onto your own apps


### Teardown

```
kind delete cluster --name ecs-m4-1

kind delete cluster --name ecs-m4-2
```

### Coming next

* Security month!
