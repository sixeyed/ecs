## ECS-V2: Logging with Elasticsearch, Fluentd and Kibana

Configuring your applications to write logs as container logs is the easy part. When you're running with dozens or hundreds of containers in production you need a centralized system to store and search your logs. One of the most popular approaches is with the EFK stack: Elasticsearch, Fluentd and Kibana.

In this episode you'll learn how to run Fluentd (and Fluent Bit) to collect all your container logs and forward them to Elasticsearch for storage. Then you have a central log store with indexed log entries, and you'll see how to use Kibana to search and visualize log data.

> Here it is on YouTube - [ECS-V1: Monitoring with Prometheus and Grafana](https://youtu.be/JlescH2xFok)

### Links


### Pre-reqs

[Docker Desktop](https://www.docker.com/products/docker-desktop) - with Kubernetes enabled (Linux container mode if you're running on Windows).

### Demo 1 - Fluentd with Docker

The basic requirement here is to have your application logs written to stdout, so they're available as container logs.

_Try a simple app:_

```
docker run diamol/ch12-timecheck:1.0
```

Docker has a plugin system so it can send logs to different collectors. [Fluentd]() is supported out of the box.

_Run a Fluentd container to collect container logs:_

```
docker run -d --name fluentd `
  -p 24224:24224 `
  -v "$(pwd)/demo1:/fluentd/etc" -e FLUENTD_CONF=stdout.conf `
  diamol/fluentd

docker logs fluentd
```

You'll see some log entries from Fluentd itself. The collection config the container is using is in [stdout.conf](demo1/stdout.conf).

Fluentd is listening on port 24224 so Docker can send container logs to `localhost`.

_Run the app container using Fluentd logging:_

```
docker run -d --name timecheck `
 --log-driver=fluentd `
 diamol/ch12-timecheck:1.0

docker logs -f timecheck

docker logs -f fluentd
```

The app container logs are shown in the Fluentd container logs.

> Previous versions of Docker wouldn't show container logs with the Fluentd driver

### Demo 2 - EFK with Docker Swarm

The EFK stack uses Fluentd to collect logs and forward them to Elasticsearch for storage. Kibana is the front-end to visualize and search the logs.

_Clean up and switch to Swarm mode:_

```
docker rm -f $(docker ps -aq)

docker swarm init
```

We'll deploy EFK as its own stack using this manifest - [logging.yml](demo2/logging.yml).

The Fluentd configuration is in [fluentd-es.conf](demo2/config/fluentd-es.conf).


```
docker config create fluentd-es demo2/config/fluentd-es.conf

docker stack deploy -c demo2/logging.yml logging

docker service ls

docker service logs logging_fluentd

docker ps
```

> Open Kibana at http://localhost:5601; add an index pattern for `fluentd*`

Now deploy the app as a separate stack, configured to use the Fluentd driver. With the global Fluentd service, every container will use the Fluentd collector running locally on the node. 

Here's the application manifest: [timecheck.yml](demo2/timecheck.yml ).

_Deploy the app:_

```
docker stack deploy -c demo2/timecheck.yml timecheck

docker stack ps timecheck

docker service logs timecheck_timecheck
```

> Check in Kibana at http://localhost:5601 - apply filter on the `app_name`. All the replica logs are collected and stored.

### Demo 3 - EFK with Kubernetes

You can run the same stack with Kubernetes - the architecture is the same, but the Fluentd collector configuration is different.

Kubernetes writes container logs to files on the nodes, so Fluentd will use those log files as the source.

_Clear down and check Kubernetes:_

```
docker swarm leave -f

docker ps 

kubectl get nodes

kubectl get ns
```

We're going to use [Fluent Bit]() which is lighter than Fluentd but has a similar config pipeline.

The key specs are:

- [fluentbit-config.yaml](demo3/logging/fluentbit-config.yaml) - the logging configuration

- [fluentbit.yaml](demo3/logging/fluentbit.yaml) - to run FluentBit as a DaemonSet.

_Deploy EFK:_

```
kubectl apply -f demo3/logging/

kubectl -n logging get pods 

kubectl -n logging logs -l app=fluent-bit
```

> Browse to the new Kibana at http://localhost:5602 - create index pattern for `sys`

All the Kubernetes system component logs are stored in this index - Fluent Bit uses separate indexes for different namespaces.

In the app manifest [timecheck.yaml](demo3\timecheck\timecheck.yaml) there's no logging setup. The app deploys to the `default` namespace, and Fluent Bit is configured to collect all logs from Pods in that namespace.

_Deploy the timecheck app:_

```
kubectl apply -f demo3/timecheck/
```

> Refresh Kibana at http://localhost:5602 - create an index pattern for `apps`; back in the Discover tab select the apps index and check logs

Any app deployed to the `default` namespace will have logs collected.

_Deploy the APOD app:_

```
kubectl apply -f demo3/apod/

kubectl get po
```

> Browse to the app at http://localhost:8014; refresh Kibana at http://localhost:5602 and check the `kubernetes.labels.app` field

### Teardown

All the Kubernetes resources are labelled.

_Delete them:_

````
kubectl delete ns,svc,deploy,clusterrole,clusterrolebinding -l ecs=v2
```


### Coming next

* ECS-V3: Distributed Tracing with OpenTracing and Jaeger