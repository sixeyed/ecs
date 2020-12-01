## ECS-C1: Continuous Integration with Docker and Jenkins

Continuous Integration is about building your apps on every change and on a regular schedule. It used to mean maintaining and managing build servers and complex build scripts - where the build for production was nothing like the developer workflow. Not any more...

In this episode we'll combine multi-stage Dockerfiles with a build infrastructure running in containers, to make for a simple and portable approach to CI. We'll use Jenkins and run all the components locally using Docker.

> Here it is on YouTube - [ECS-C1: Continuous Integration with Docker and Jenkins](https://youtu.be/MBDxDM4NkbI)

### Links

* [DIAMOL episode 11 - Building and testing applications with Docker and Docker Compose](https://youtu.be/lO-Lwwy04zs)

### Pre-reqs

You can use [Docker Desktop](https://www.docker.com/products/docker-desktop) on Windows 10 or Mac, or [Docker Community Edition](https://docs.docker.com/engine/install/) on Linux to follow the demos.


### Demo 1 - Spinning up the build infrastructure

```
docker-compose -f ./infrastructure/docker-compose.yml up -d
```

curl http://registry.local:5000/v2/_catalog

http://localhost:3000

* Sqlite DB
* create user ecs
* create repo ecs - issues & wiki

```
git remote add local http://localhost:3000/ecs/ecs.git
```

> See [Diamol ep. 10](https://youtu.be/lO-Lwwy04zs) for automation options

### Demo 2 - Building Docker images with Jenkins


Build locally: 

```
docker-compose -f .\src\docker-compose.yml build

docker image inspect sixeyed/image-of-the-day:ecs-c1
```



docker logs infrastructure_jenkins_1

docker exec infrastructure_jenkins_1 cat /var/jenkins_home/secrets/initialAdminPassword


localhost:8080

* ecs/ecs
* new item - pipeline
* schedule @daily
* poll scm * * * * * 

* git - http://gogs:3000/ecs/ecs.git



### Demo 3 - Running tests in containers



### Coming next

ECS-C2: CI/CD with Docker and GitHub Actions
