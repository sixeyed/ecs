## ECS-V2: Logging with Elasticsearch, Fluentd and Kibana

Configuring your applications to write logs as container logs is the easy part. When you're running with dozens or hundreds of containers in production you need a centralized system to store and search your logs. One of the most popular approaches is with the EFK stack: Elasticsearch, Fluentd and Kibana.

In this episode you'll learn how to run Fluentd (and Fluent Bit) to collect all your container logs and forward them to Elasticsearch for storage. Then you have a central log store with indexed log entries, and you'll see how to use Kibana to search and visualize log data.

> Here it is on YouTube - [ECS-V1: Monitoring with Prometheus and Grafana](https://youtu.be/JlescH2xFok)

### Links


### Pre-reqs

[Docker Desktop](https://www.docker.com/products/docker-desktop) - with Kubernetes enabled (Linux container mode if you're running on Windows).

### Demo 1 - Fluentd with Docker

```
docker run diamol/ch12-timecheck:1.0
```

```
docker run -d --name fluentd `
  -p 24224:24224 `
  -v "$(pwd)/demo1:/fluentd/etc" -e FLUENTD_CONF=stdout.conf `
  diamol/fluentd

docker logs fluentd
```

stdout.conf

```
docker run -d --name timecheck `
 --log-driver=fluentd `
 diamol/ch12-timecheck:1.0

docker logs -f timecheck

docker logs -f fluentd
```

> Previous versions of Docker wouldn't show container logs with the Fluentd driver

### Demo 2 - EFK with Docker Swarm

```
docker rm -f $(docker ps -aq)

docker swarm init
```

logging.yml

```
docker config create fluentd-es demo2/config/fluentd-es.conf

docker stack deploy -c demo2/logging.yml logging

docker service ls

docker service logs logging_fluentd

docker ps
```

http://localhost:5601

timecheck.yml

```
docker stack deploy -c demo2/timecheck.yml timecheck

docker stack ps timecheck

docker service logs timecheck_timecheck
```

http://localhost:5601 - apply filter

### Demo 3 - EFK with Kubernetes

_Clear down and check Kubernetes:_

```
docker swarm leave -f

docker ps 

kubectl get nodes

kubectl get ns
```

```
kubectl apply -f demo3/logging/

kubectl -n logging get pods 

kubectl -n logging logs -l app=fluent-bit --tail 50
```

http://localhost:5601 - create index for `sys`

```
kubectl apply -f demo3/timecheck/
```

http://localhost:5601 - create index for `apps`

```
kubectl apply -f demo3/apod/

kubectl get po
```

http://localhost:8014

http://localhost:5601

### Teardown

````
kubectl delete ns,svc,deploy,clusterrole,clusterrolebinding -l ecs=v2
```


### Coming next

* ECS-V3: Distributed Tracing with OpenTracing and Jaeger