## ECS-C1: Continuous Integration with Docker and Jenkins

Continuous Integration is about building your apps on every change and on a regular schedule. It used to mean maintaining and managing build servers and complex build scripts - where the build for production was nothing like the developer workflow. Not any more...

In this episode we'll combine multi-stage Dockerfiles with a build infrastructure running in containers, to make for a simple and portable approach to CI. We'll use Jenkins and run all the components locally using Docker.

> Here it is on YouTube - [ECS-C1: Continuous Integration with Docker and Jenkins](https://youtu.be/MBDxDM4NkbI)

### Links

* [GitHub Actions](https://gogs.io) - "a painless self-hosted Git service"


### Pre-reqs

GitHub.

### Demo 1 - Building and pushing images

We'll run a full build stack - Git server, automation server and container registry.

The spec is in [infrastructure/docker-compose.yml](./infrastructure/docker-compose.yml), using project team images from Docker Hub, except Jenkins which is a custom build in [images/jenkins/Dockerfile](./images/jenkins/Dockerfile).

_Spin up the infrastructure:_

```
docker-compose -f ./infrastructure/docker-compose.yml up -d
```

_Check the registry server:_

```
curl http://registry.local:5000/v2/_catalog
```

_And setup Gogs:_

http://localhost:3000

Finish the configuration and create a user and repo:

* Select Sqlite DB & install with defaults
* Create user `ecs`
* Create repo `ecs` - Gogs has issues & wiki like GitHub

_Add the local Git server as a remote:_

```
git remote add local http://localhost:3000/ecs/ecs.git
```

> See [Diamol ep. 10](https://youtu.be/lO-Lwwy04zs) for automation options

### Demo 2 - Building Docker images with Jenkins

We have a distributed app to build in the `src` directory:

* [access-log/Dockerfile](./src/access-log/Dockerfile) - a Node.js REST API
* [image-of-the-day/Dockerfile](./src/image-of-the-day/Dockerfile) - a JAVA REST API
* [image-gallery/Dockerfile](./src/image-gallery/Dockerfile) - a Go web server
* [docker-compose.yml](./src/docker-compose.yml) - the Compose file to build and run the app

Build arguments get used as labels to provide an audit trail from the final image.

_Build the app locally:_

```
docker-compose -f ./src/docker-compose.yml build

docker image inspect sixeyed/image-of-the-day:ecs-c1
```

> Default label values for the local build

_Check Jenkins is up and running:_

```
docker logs infrastructure_jenkins_1
```

It's provisioned with two scripts - [admin.groovy](./infrastructure/jenkins/admin.groovy) sets the admin user credentials and [install-plugins.groovy](./infrastructure/jenkins/install-plugins.groovy) installs the Pipeline plugin.

> Browse to Jenkins at http://localhost:8080

* Log in with creds `ecs`/`ecs`
* Create a new item - select Pipeline Job
* Set the schedule `@daily`
* And poll scm `* * * * * `

_Configure the source repo to use Gogs:_

* git - `http://gogs:3000/ecs/ecs.git`
* path - `episodes/ecs-c1/src/Jenkinsfile`

> Build now and check the logs

Jenkins is using this [Jenkinsfile](.\src\Jenkinsfile). It runs Docker commands using the local Docker Engine - from the bind mounted socket. 

_Check the images it builds are in the local image cache:_

```
docker image ls registry.local:5000/*/*

docker image inspect registry.local:5000/ecs/image-gallery:ecs-c1
```

### Demo 3 - Running tests in containers

Your CI process can run end-to-end tests in containers and push the app images to a local registry. 

Then it would go on to do security scanning and signing before pushing to a production repo for release.

There's a simple test container in [e2e-test/Dockerfile](./src/e2e-test/Dockerfile) - it connects to the image API container using the container name.

_Change the Jenkins job at http://localhost:8080/job/ecs-c1/configure_

* Set path - `episodes/ecs-c1/src/Jenkinsfile.v2`

> Build now and check logs

The new pipeline uses the job in [Jenkinsfile.v2](.\src\Jenkinsfile.v2).

_Verify the new build:_

```
docker image inspect registry.local:5000/ecs/image-gallery:ecs-c1
```

_And check the images in the local registry:_

```
curl http://registry.local:5000/v2/_catalog

curl http://registry.local:5000/v2/ecs/access-log/tags/list
```

### Coming next

[ECS-C2: CI/CD with Docker and GitHub Actions](https://youtu.be/HCk-_bssu4w)
