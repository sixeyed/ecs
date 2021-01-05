## ECS-V1: Monitoring with Prometheus and Grafana

Monitoring for containerized apps is easy when you understand the patterns, and plug in some great open-source software. In this episode you'll learn the architecture of exporting metrics from containers and collecting them in a central server.

We'll use the leading tools to power collection and visualization of metrics: Prometheus and Grafana. You'll see how to use them with Docker and Kubernetes and how they power a consistent monitoring approach for all your application components.

> Here it is on YouTube - [ECS-V1: Monitoring with Prometheus and Grafana](https://youtu.be/JlescH2xFok)

### Links

* [Getting Started with Prometheus](https://app.pluralsight.com/library/courses/getting-started-prometheus/table-of-contents) - my Pluralsight course

* [Docker for .NET Apps](http://eepurl.com/hji6Hb) - sign up to know when my new Udemy course is released

### Pre-reqs

Docker Desktop.


### Demo 1 - scraping container metrics with Prometheus

```
cd demo1

docker-compose up -d
```

http://localhost:8010/

http://localhost:8010/metrics

http://localhost:8012/metrics

http://localhost:8011/actuator/prometheus


```
docker-compose -f .\docker-compose-prometheus.yml up -d
```

[config/prometheus.yml]

http://localhost:9090/config

http://localhost:9090/graph

Runtime metrics - OS:

- `process_cpu_seconds_total`
- `process_cpu_usage`

Runtime metrics - platform:

- `go_goroutines`
- `http_server_requests_seconds_count`

Application metrics:

- `access_log_total`
- `iotd_api_image_load_total`

### Demo 2 - service discovery in Docker Swarm

```
docker-compose -f docker-compose.yml -f docker-compose-prometheus.yml down

cd ../demo2

docker swarm init

docker config create prometheus config/prometheus.yml

docker stack deploy -c prometheus.yml prometheus

```

http://localhost:9090/config

http://localhost:9090/service-discovery


```
docker stack deploy -c apod.yml apod
```

http://localhost:9090/service-discovery

http://localhost:8010/

http://localhost:9090/graph

- `image_gallery_requests_total`
- `iotd_api_image_load_total`

> Refresh UI lots and check metrics again

> Switch to graph mode

### Demo 3 - service discovery in Kubernetes

```
docker swarm leave -f

docker ps 

kubectl get nodes

kubectl get ns
```

Prometheus


```
cd .../demo3

kubectl apply -f ./prometheus/

kubectl get all -n monitoring
```

http://localhost:9091/service-discovery


```
kubectl apply -f ./apod/

kubectl get pods -n default
```

http://localhost:9091/targets

http://localhost:8014/

http://localhost:9091/graph


```
kubectl apply -f ./grafana/

kubectl get pods -n monitoring
```

http://localhost:3000

- `ecs`/`ecs`

### Teardown

````
kubectl delete ns,svc,deploy,clusterrole,clusterrolebinding -l ecs=v1
```

### Coming next


* ECS-V2: Centralized Logging with Elasticsearch, Fluentd and Kibana