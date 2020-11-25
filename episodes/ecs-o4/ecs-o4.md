## ECS-O3: Containers in Production with Nomad

Nomad is a workload orchestrator. It uses a generic specification for tasks which can run in containers, or as a VM, or in a Java environment or as a process on a server. The Docker driver lets you use Nomad as a pure container orchestrator.

Nomad is quite different to Docker Swarm and Kubernetes, and it's not a complete solution on its own. In a production environment it becomes the compute part of a full HashiCorp stack, with Consul for service discovery and Vault for sensitive data storage.

In this episode we'll see a couple of options for running Nomad, and deploying containerized applications.

> Here's it is on YouTube - [ECS-O4: Containers in Production with Nomad](https://youtu.be/EJjAQGC7rVs)

### Links

* [is.gd/idobeh](https://is.gd/idobeh) - Black Friday, 40% off Pluralsight subscriptions!

* [is.gd/icitic](https://is.gd/icitic) - Docker for .NET Apps, sign up for notifications

* [is.gd/wipaxi](https://is.gd/wipaxi) - Elton on the Semaphore podcast, talking about the challenges of learning Kubernetes

* [Nomad tutorials from HashiCorp Learn](https://learn.hashicorp.com/nomad)

* [Nomad job specification API](https://www.nomadproject.io/docs/job-specification)

* [Docker's Voting App on Swarm, Kubernetes and Nomad](https://medium.com/better-programming/dockers-voting-app-on-swarm-kubernetes-and-nomad-8835a82050cf) - comparison by Docker Captain [Luc Juggery](https://www.docker.com/captains/luc-juggery)

### Pre-reqs

I'm running Linux VMs for the Kubernetes cluster using [Vagrant](https://www.vagrantup.com).

You can set the VMs up with:

```
cd episodes/ecs-o4/vagrant

vagrant up
```

> You can also try Nomad in an [interactive lab](https://learn.hashicorp.com/collections/nomad/interactive).

## Run Nomad in dev mode

The [setup.sh](./vagrant/setup.sh) script installs Docker and Nomad in the simplest way.

_Connect to the dev VM and start the Nomad agent in dev mode:_

```
vagrant ssh dev

nomad agent -dev
```

> Starts in server + client mode, suitable for lab environments.

Drivers show the available workloads - `docker` for containers and `raw_exec` for binaries. Others are available - e.g for Java apps, QEMU VMs, and isolated binaries.

Apps are modelled for Nomad using HCL. This simple app spec in [whoami.nomad](./whoami.nomad) models a REST API running in a Docker container.

_Restart Nomad in the background and deploy the app:_

```
[Ctrl-C]

nomad agent -dev > /dev/null & 

nomad node status

cd /ecs-o4

nomad job run whoami.nomad
```

_Check the status of the job and the container:_

```
nomad status whoami

docker ps

curl localhost:8080
```

Nomad servers are the control plane, monitoring jobs and tasks. Clients run user workloads. If a task fails on the client, the server will replace it.

_Remove the container and check the job status:_

```
docker ps -lq

docker rm -f $(docker ps -lq)

nomad status whoami

docker ps

curl localhost:8080
```

Networking in this setup is just port publishing - like host mode in Docker Swarm. You can't scale up to more tasks than there are client nodes because each task uses a port.

_Edit the count in [whoami.nomad](./whoami.nomad) to 2 and update:_

```
nomad job run whoami.nomad

nomad status whoami

curl localhost:8080
```

## Run a multi-container task group

Nomad doesn't provide service discovery on its own - it expects to integrate with a Consul cluster. Nomad can use Consul for node discovery and for service discovery.

Try to deploy a distributed app like [todo-list-dev.nomad](./todo-list-dev.nomad) and it will run, but the containers can't find each other.

_Run the to-do list app with db and web tasks:_

```
nomad job run todo-list-dev.nomad

nomad status todo

docker ps
```

_Check the status of the group:_

```
nomad alloc status [ID]

nomad alloc logs [ID] web
```

_Test the app:_

```
curl -v http://localhost:8010

nomad alloc logs [ID] web
```

> You can run Consul in dev mode too, but we'll skip onto running a more production-like cluster.

## Run a cluster with Nomad with Consul

Consul is a service catalogue and a DNS server. It works with Nomad to register services as DNS endpoints, and resolve DNS queries to task addresses - e.g. container IP addresses.

You can run a clustered Consul setup with server and client nodes. Each node runs a local agent, and that agent gets used for lookups.

The [setup-prod.sh](./vagrant/setup-prod.sh) script installs Consul and runs it as a service. It also configures the VM to use Consul for DNS lookups.

_Connect to the server and verify Consul is running:_

```
vagrant ssh server

consul members
```

> Get the IP address of the server for other nodes to join

_Join the client node to Consul:_

```
vagrant ssh client

consul members

consul join #[SERVER-IP]
```

_And the second client node:_

```
vagrant ssh client2

consul join #[SERVER-IP]

consul members
```

> Now all the servers are in a Consul cluster, for shared service discovery

## Start Nomad

A Nomad cluster runs as server and client nodes - typically 3 servers for production. We'll use a basic setup in [server.hcl](./server.hcl) which uses a single server node.

_Start Nomad on the server:_

```
vagrant ssh server

cd /ecs-o4

nomad agent -config server.hcl > /dev/null &

nomad node status
```

> The server node is the control plane. Server nodes are only for management and won't run any user workloads.

We'll add the other VMs as clients to the cluster using the configuration in [client.hcl](./client.hcl). Nomad will use Consul to find the Nomad server.

_Join the client to the Nomad cluster:_

```
vagrant ssh client

consul catalog services

cd /ecs-o4

nomad agent -config client.hcl > /dev/null &
```

_And the second client:_

```
vagrant ssh client2

cd /ecs-o4

nomad agent -config client.hcl > /dev/null &
```

_Check the cluster status:_

```
vagrant ssh server

nomad node status
```

> Now we have a Nomad cluster with multiple nodes and Consul integration.

## Run the who-am-i app

The same [whoami.nomad](./whoami.nomad) spec will work on the cluster. With two nodes we can run two instances of the group.

_Deploy the job:_

```
cd /ecs-o4

nomad job run whoami.nomad

nomad status whoami

nomad alloc status [ID]
```

> Browse to the allocation address. 

Port publishing is like host mode in Swarm or NodePorts in Kubernetes - but only on the server hosting the task. You don't get a routing mesh where any server can receive incoming traffic and send it to the container.

## Distributed apps in Nomad

With Consul integration we can publish services which route to tasks, so applications can use DNS to reach other components. The app spec in [todo-list.nomad](./todo-list.nomad) uses a service for the database, and configures DNS in the web container to use Consul.

> Edit [todo-list.nomad](./todo-list.nomad) to add the server IP for DNS lookup.

_Deploy the app as one group:_

```
nomad job run todo-list.nomad

nomad job status todo

nomad alloc status [ID]
```

> All the tasks in the group run on the same node.

Check the database service is registered in DNS:

```
consul catalog services

dig @localhost SRV todo-db.service.consul

dig @localhost todo-db.service.dc1.consul
```

> Browse to allocation address for the app and test

Defining a distributed application as tasks in one group doesn't give you a scalable solution. We'll remove this deployment and run a more production-y job.

_Stop the application job:_

```
nomad job stop todo
```

> There's no delete functionality - old jobs get garbage-collected by the server.

## V2 - production-like config

The new spec breaks the database and web components into separate groups:

* [todo-db.nomad](./todo-list-v2/todo-db.nomad) - adds resource constraints and a service check
* [todo-web.nomad](./todo-list-v2/todo-web.nomad) - runs multiple instances and loads config from an artifact

_Deploy the database job:_

```
cd /ecs-o4/todo-list-v2

nomad job run todo-db.nomad

nomad job status todo-db
```

> Edit [todo-web.nomad](./todo-list-v2/todo-web.nomad) & add server IP for DNS

_Deploy the web job:_

```
nomad job run todo-web.nomad

nomad job status todo-web
```

> Browse to the allocation address and test the app.

### Coming next

* ECS-C1: Continuous Integration with Containers and Jenkins