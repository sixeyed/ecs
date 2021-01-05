## ECS-V1: Monitoring with Prometheus and Grafana

Monitoring for containerized apps is easy when you understand the patterns, and plug in some great open-source software. In this episode you'll learn the architecture of exporting metrics from containers and collecting them in a central server.

We'll use the leading tools to power collection and visualization of metrics: Prometheus and Grafana. You'll see how to use them with Docker and Kubernetes and how they power a consistent monitoring approach for all your application components.

> Here it is on YouTube - [ECS-V1: Monitoring with Prometheus and Grafana](https://youtu.be/JlescH2xFok)

### Links

* [Adding observability with containerized monitoring](https://youtu.be/6BcoR79AOas) - DIAMOL episode 08

* [Getting Started with Prometheus](https://app.pluralsight.com/library/courses/getting-started-prometheus/table-of-contents) - my Pluralsight course

* [Docker for .NET Apps](http://eepurl.com/hji6Hb) - sign up to know when my new Udemy course is released, includes monitoring for .NET Framework and Core apps

### Pre-reqs

[Docker Desktop](https://www.docker.com/products/docker-desktop) - with Kubernetes enabled (Linux container mode if you're running on Windows).

### Demo 1 - scraping container metrics with Prometheus

The first step in monitoring containerized apps is to add metrics to every component. 

The APOD app ([source code](https://github.com/sixeyed/kiamol/tree/master/ch14/docker-images)) does this using Prometheus client libraries, with examples in Go, Node.js and Java.

Start the app:

```
cd demo1

docker-compose up -d
```

Browse to:

- the app at http://localhost:8010/

- the Go web server metrics at http://localhost:8010/metrics

- the Node.js log API metrics at http://localhost:8012/metrics

- the Java image API metrics at http://localhost:8011/actuator/prometheus


[Prometheus](https://prometheus.io) is the server component which collects and stores application metrics from the containers.

Run Prometheus in a container, defined in [docker-compose-prometheus.yml](demo1/docker-compose-prometheus.yml). This is configured to collect metrics from all the APOD components:

```
docker-compose -f docker-compose-prometheus.yml up -d
```

> Prometheus is configured using simple domain names in [prometheus.yml](demo1/config/prometheus.yml); those are the container names specified in the app's [docker-compose.yml](demo1/docker-compose.yml)

Browse to:

- Prometheus config UI at http://localhost:9090/config

- the query UI at http://localhost:9090/graph

_Query some runtime OS metrics:_

- `process_cpu_seconds_total`
- `process_cpu_usage`

_And some platform metrics:_

- `go_goroutines`
- `http_server_requests_seconds_count`

_And custom application metrics:_

- `access_log_total`
- `iotd_api_image_load_total`

### Demo 2 - service discovery in Docker Swarm

Running at scale means you can't use static domain names - Prometheus needs to collect from every container, not go through a load-balancer.

Prometheus supports dynamic service discovery for many platforms, including Docker Swarm.

_Switch to Swarm mode and deploy Prometheus, configured with service discovery:_

```
docker-compose -f docker-compose.yml -f docker-compose-prometheus.yml down

cd ../demo2

docker swarm init

docker config create prometheus config/prometheus.yml

docker stack deploy -c prometheus.yml prometheus
```

The configuration in [prometheus.yml](demo2/config/prometheus.yml) is more complex; it models an opt-in approach, where components state if they want to have metrics scraped using labels.

Browse to:

- the Prometheus config at http://localhost:9090/config

- discovered services at http://localhost:9090/service-discovery

_Now deploy the APOD app as a Swarm stack:_

```
docker stack deploy -c apod.yml apod
```

The [apod.yml](demo2/apod.yml) app definition includes the Prometheus setup in the service labels.

Browse to:

- the new app at http://localhost:8010/

- the updated service list at http://localhost:9090/service-discovery

- graphs at http://localhost:9090/graph

- `image_gallery_requests_total`
- `iotd_api_image_load_total`

> Refresh UI lots and check metrics again

> Switch to graph mode

### Demo 3 - service discovery in Kubernetes

It's the same principle in Kubernetes - deploying Prometheus with a configuration to connect to the Kubernetes API for service discovery.

_Clear down and check Kubernetes:_

```
docker swarm leave -f

docker ps 

kubectl get nodes

kubectl get ns
```

The configuration in [prometheus-config.yaml](demo3\prometheus\prometheus-config.yaml) shows an alternative approach - an opt-out model, where Pods within the default namespace are included unless they have an annotation to exclude them.

_Deploy Prometheus to Kubernetes:_


```
cd ../demo3

kubectl apply -f ./prometheus/

kubectl get all -n monitoring
```

> Prometheus needs access to query the Kubernetes API, so this deployment includes RBAC resources.

Browse to:

- Prometheus service discovery at http://localhost:9091/service-discovery


_Now deploy the APOD app into the default namespace :_

```
kubectl apply -f ./apod/

kubectl get pods -n default
```

Browse to:

- the new app at http://localhost:8014/

- Prometheus target list at http://localhost:9091/targets

- metrics at http://localhost:9091/graph

The raw metrics can be used to drive a Grafana dashboard.Grafana runs in a Pod and connects to the Prometheus API to run queries and visualize the results.

_Deploy Grafana, with a pre-configured APOD dashboard:_

```
kubectl apply -f ./grafana/

kubectl get pods -n monitoring
```

Browse to:

- http://localhost:3000

- sign in with credentials `ecs`/`ecs`

- check the APOD dashboard

### Teardown

````
kubectl delete ns,svc,deploy,clusterrole,clusterrolebinding -l ecs=v1
```

### Coming next

* ECS-V2: Centralized Logging with Elasticsearch, Fluentd and Kibana