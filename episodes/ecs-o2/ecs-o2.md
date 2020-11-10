## ECS-O2: Containers in Production with Docker Swarm

Docker Swarm is the production-grade orchestrator built into Docker. There are no managed Swarm services in the cloud, but you can run a supported cluster in the datacenter with [Docker Enterprise](https://www.mirantis.com/software/docker/docker-enterprise/) (previously a Docker product, now owned by Mirantis).

Swarm is an opinionated orchestrator which is simple to work with. It uses the Docker Compose specification to model applications so it's easy for people to transition from Compose on a single machine to a Swarm cluster.

In this episode we create a Swarm cluster and deploy some applications, showing how the Compose spec can be extended to include production concerns.

> Here's it is on YouTube - [ECS-O2: Containers in Production with Docker Swarm](https://youtu.be/JzXNLYJlTqk)

### Links

* [Docker Swarm mode overview](https://docs.docker.com/engine/swarm/)

* [DIAMOL episode 12: Deploying distributed apps as stacks in Docker Swarm](https://youtu.be/JUEDHPNCs0U)

*  [DIAMOL episode 13: Automating releases with upgrades and rollbacks](https://youtu.be/XWUfb08qDYg)

* [Pluralsight: Managing Load Balancing and Scale in Docker Swarm Mode Clusters](https://pluralsight.pxf.io/PXRkz)

* [Pluralsight: Handling Data and Stateful Applications in Docker](https://pluralsight.pxf.io/jkQ2e) _(includes distributed storage in Swarm clusters)_

* [Ongoing support for Docker Swarm from Mirantis](https://www.mirantis.com/blog/mirantis-will-continue-to-support-and-develop-docker-swarm/)

### Pre-reqs

I'm running Linux VMs for the Swarm cluster using [Vagrant](https://www.vagrantup.com).

You can set the VM up with:

```
cd episodes/ecs-o2/vagrant

vagrant up
```

> You can run all the examples with Docker Desktop, except for the node management section because you'll only have a single node.

### Demo 1 - Initializing the cluster

The orchestration component in Docker Swarm is a separate open-source project called [SwarmKit](https://github.com/docker/swarmkit). It's baked into the Docker Engine so when you run in Swarm mode there are no additional components.

_Initialize the Swarm on the manager node:_

```
vagrant ssh manager

docker swarm init

docker swarm join-token manager

docker swarm join-token worker

exit
```

> You now have a functional single-node Swarm. The output shows the command you run on other nodes to join the Swarm. 

_Join the worker nodes:_

```
vagrant ssh worker1

[docker swarm join]

exit
```

> Run the `docker swarm join` command from the manager node.

```
vagrant ssh worker2

[docker swarm join]

exit
```

_Check the cluster status:_

```
vagrant ssh manager

docker node ls

docker node inspect worker1
```

> Nodes are top-level objects, but you need to be connected to a manager to work with them.

### Demo 2 - Running Docker Swarm services

Swarm mode takes the _service_ abstraction from Docker Compose and makes it into a first-class object. You can create services on the Swarm, and the orchestrator schedules containers to run.

_Deploy a basic web app:_

```
docker service create --name apache -p 8080:80 diamol/apache

docker service ps apache

docker node inspect worker1 -f '{{.Status.Addr}}'

docker node inspect worker2 -f '{{.Status.Addr}}'
```

> There's a single container running, but you can browse to port `8080` on any node and the traffic gets routed to the container.

_Scale up and more containers will be created - incoming requests get load-balanced between them:_

```
docker service update --replicas 10 apache

docker service ps apache

docker node inspect manager -f '{{.Status.Addr}}'
```

> Browse to the site and refresh a few times

_Check the logs and clear up:_

```
docker service logs apache

docker service rm apache

docker ps
```

### Demo 3 - Deploying a Docker Compose manifest

Swarm can run applications defined for Docker Compose - any parts of the Compose spec which aren't relevant in Swarm mode (like `depends_on`) get ignored.

This simple [docker-compose.yml](./docker-compose.yml) file is perfectly valid to run in the cluster. It gets deployed as a [stack](https://docs.docker.com/engine/reference/commandline/stack/), which is a grouping for services, networks and other resources.

_Deploy the app as a stack:_

```
cd /ecs-o2

docker stack deploy -c docker-compose.yml todo1

docker network inspect todo1_todo-net
```

> In Swarm mode the default network driver is `overlay`, which spans all the nodes in the cluster.

_Check the resources:_

```
docker stack ls

docker stack services todo1 

docker stack ps todo1
```

> Browse to a node on port `8010`.

### Demo 4 - Deploying a production-grade Docker stack

The cluster has it's own HA database, replicated across all the manager nodes (typically 3 in a production cluster). The database stores all the app specs and you can use it for configuration objects.

That lets you separate configuration management from app management. We'll deploy the to-do app next using custom config objects: [todo-web-config.json](./configs/todo-web-config.json) and  [todo-web-secrets.json](./secrets/todo-web-secrets.json) 

_Create the app config in the Swarm:_

```
docker config create todo-web-config ./configs/todo-web-config.json

docker config ls

docker config inspect todo-web-config --pretty
```

> Anyone can read the contents of a config object.

_And the secret:_

```
docker secret create todo-web-secrets ./secrets/todo-web-secrets.json

docker secret ls

docker secret inspect todo-web-secrets --pretty
```

> Secrets are encrypted and can only be read inside the container filesystem.

This new [docker-stack.yml](./docker-stack.yml) spec models the to-do app with configs and secrets mounted into the container.

_Deploy the new stack:_

```
docker stack deploy -c docker-stack.yml todo2

docker stack ps todo2
```

_In a new window open a session to the node running the container and check the filesystem:_

```
vagrant ssh [node]

docker ps

docker exec -it [container] sh

ls -l /app/config

cat /app/config/config.json

cat /app/config/secrets.json

exit
```

For a production deployment you would also add healthchecks, update and rollback configuration, security settings (like user IDs for the container processes) and more. 

There's some extra production detail in [docker-stack-2.yml](./docker-stack-2.yml) - adding process constraints to the containers, and running multiple replicas of the web app.

_Back on the manager node, update the stack:_

```
docker stack deploy -c docker-stack-2.yml todo2

docker stack ps todo2
```

> The update happens as a staged rollout. Try the app at `:8020`

### Demo 5 - Node management

Creating a Swarm is easy, and so is managing the nodes in the Swarm/

_Take a node out of action for maintenance:_

```
docker service ps todo2_todo-web

docker node update --availability drain worker1

docker node ls

docker node ps worker1

docker service ps todo2_todo-web
```

> Containers are shut down and replaced on other nodes. Drained nodes won't schedule any more containers.

_Bring the node back online:_

```
docker node update --availability active worker1

docker node ps worker1

docker node ls
```

> The node is back online, but running services aren't automatically rebalanced.

_Update a service to force rebalancing:_

```
docker service update --force todo2_todo-web

docker service ps todo2_todo-web -f "desired-state=running"
```

### Teardown

_Delete stacks and leave the Swarm:_

```
docker stack rm $(docker stack ls)

docker ps

docker swarm leave -f

docker node ls

exit
```

> Repeat the `swarm leave` command on all nodes.

_Remove all the VMs:_

```
vagrant destroy
```

### Coming next

* ECS-O2: Containers in Production with Kubernetes
