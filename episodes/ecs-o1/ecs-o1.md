## ECS-O1: Understanding Container Orchestration

Orchestration means using a container platform to manage your apps. Instead of running containers yourself, you send a model of your app to the orchestrator and it runs the containers. 

The most popular orchestrator is Kubernetes, which is hugely powerful but complex - in the next few episodes we'll compare Kubernetes, Docker Swarm and Nomad.

This episode looks at the basic feature set in orchestration and looks at how Docker Compose measures up compared to full container platforms.

> Here it is on YouTube - [ECS-O1: Understanding Container Orchestration](https://youtu.be/F7rORInGvc4)


### Slides

We start this week with some slides to set the scene. 

You'll find them here in [ecs-o1.pptx](ecs-o1.pptx).

### Links

* [Deploying Docker containers on Azure](https://docs.docker.com/engine/context/aci-integration/)

* [Learn Docker in a Month of Lunches - the book](https://www.manning.com/books/learn-docker-in-a-month-of-lunches?utm_source=affiliate&utm_medium=affiliate&a_aid=elton&a_bid=5890141b)

* [DIAMOL episode 06 - Running multi-container apps with Docker Compose](https://youtu.be/3bs4HDBRPgk)

* [Awesome Compose](https://github.com/docker/awesome-compose)

### Pre-reqs

You can use [Docker Desktop](https://www.docker.com/products/docker-desktop) to follow the Compose demos.

I'm using a separate Linux VM running Docker, using [Vagrant](https://www.vagrantup.com).

You can set that VM up with:

```
cd episodes/ecs-o1/vagrant

vagrant up linux

vagrant ssh linux
```

### Demo 1 - Docker Compose is not an orchestrator

This [Docker Compose](docker-compose.yml) file has all the orchestrator-y features, with abstractions for compute and networking and config injection.

But Docker Compose is just a client-side tool which does a manual reconcilation with the Docker Engine when you run `up` commands. It doesn't manage containers for you.

_Run the boring to-do demo app:_

```
cd /ecs-o1

docker-compose up -d

ip address
```

> Browse to the app on the host port `8030` and add an item

_Now kill the app process:_

```
docker exec ecs-o1_todo-web_1 sh -c 'kill 1'

docker ps
```

> Compose doesn't restart the container

_Restart the Docker Engine:_

```
sudo service docker restart

docker ps
```

_Delete the database container and start the app again:_

```
docker rm -f ecs-o1_todo-db_1

docker-compose up -d
```

> The app works but the original data is lost


### Demo 2 - But you can configure apps for high(er) availability

You'll never get true HA running containers with Docker Compose because it only manages a single server - lose the server and you lose all your apps.

But if one server is all you have (for low-volume apps or test environments) you can increase availability with `restart` and `volume` configurations.

These are set in the updated to-do spec in [docker-compose-ha.yml](docker-compose-ha.yml).


_Clear containers and start a new copy of the app:_

```
docker rm -f $(docker ps -aq)

docker-compose -f docker-compose-ha.yml up -d

docker ps

docker volume ls
```

> Refresh the app and add a new item

_Now kill the app process:_

```
docker exec ecs-o1_todo-web_1 sh -c 'kill 1'

docker ps
```

> The container is restarted

_Restart the Docker Engine:_

```
sudo service docker restart

docker ps
```

_Delete the database container and start the app again:_

```
docker rm -f ecs-o1_todo-db_1

docker-compose -f docker-compose-ha.yml up -d
```

> The app works and shows the data - but you need to make sure you use the right Compose file


### Demo 3 - And you can use the Compose spec on other platforms

The ACI version uses the same Docker Compose spec, but using Azure Files for configuration storage, and a managed Postgres database in Azure: [docker-compose-aci.yml](docker-compose-aci.yml).

* volume for config
* restart flag
* managed postgres db

```
docker context ls

docker context use ecs-o1
```

_Deploy:_

```
cd episodes/ecs-o1

docker compose -f docker-compose-aci.yml up -d

docker ps
```

> Test the app...

### Teardown

```
docker compose down

vagrant destroy linux
```

### Coming next

[ECS-O2: Containers in Production with Docker Swarm](https://youtu.be/JzXNLYJlTqk)
