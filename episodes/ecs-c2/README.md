## ECS-C2: Continuous Deployment with Docker and GitHub

GitHub Actions is a hosted automation service. You define workflows in YAML which live in your repository, and they can be triggered by pushes, schedules, manual runs and other events. 

Jobs run in a short-lived VM which is provisioned for you, and the standard VMs include Docker so you can easily transition your Docker-powered CI/CD process to GitHub.

In this episode we'll take the multi-stage Dockerfiles from [ECS-C1](https://eltons.show/ecs-c1) and use them to build images with GitHub Actions. We'll see a couple of approaches to the workflows, finishing with a full CI/CD pipeline which deploys the sample app to a Kubernetes cluster running in Azure.

> Here it is on YouTube - [ECS-C2: Continuous Deployment with Docker and GitHub](https://youtu.be/HCk-_bssu4w)

![ECS-C2 CI/CD demo - v1](https://github.com/sixeyed/ecs/workflows/ECS-C2%20CI/CD%20demo%20-%20v1/badge.svg)

![ECS-C2 CI/CD demo - v2](https://github.com/sixeyed/ecs/workflows/ECS-C2%20CI/CD%20demo%20-%20v2/badge.svg)

![ECS-C2 CI/CD demo - v3](https://github.com/sixeyed/ecs/workflows/ECS-C2%20CI/CD%20demo%20-%20v3/badge.svg)


### Links

* [GitHub Actions](https://docs.github.com/en/free-pro-team@latest/actions) - docs 

* [Configure GitHub Actions](https://docs.docker.com/ci-cd/github-actions/) - Docker's action guide

* [Best practices for using Docker Hub for CI/CD](https://www.docker.com/blog/best-practices-for-using-docker-hub-for-ci-cd/) - Docker blog

* [Docker metadata action](https://github.com/crazy-max/ghaction-docker-meta) - from Docker Captain Crazy Max

* [Kubernetes deployment action](https://github.com/marketplace/actions/deploy-to-kubernetes-cluster) - from Microsoft

### Pre-reqs

GitHub (and an [AKS cluster](./aks.md) if you want to try the deployment).

You can clone this repo and create your own Secrets:

* `DOCKER_HUB_USERNAME`
* `DOCKER_HUB_ACCESS_TOKEN`
* `AZURE_CREDENTIALS`

### Demo 1 - basic build

The first workflow uses Docker Compose for the build - [ecs-c2-v1.yml](../../.github/workflows/ecs-c2-v1.yml), with this [Docker Compose file](./src\docker-compose.yml).

It uses [GitHub Secrets](https://github.com/sixeyed/ecs/settings/secrets/actions) for the Docker Hub credentials.

> Run the build manually from the [repository actions page](https://github.com/sixeyed/ecs/actions).

> Then check the tags in the [sixeyed/access-log repo on Docker Hub](https://hub.docker.com/repository/docker/sixeyed/access-log/tags?page=1&ordering=last_updated).

Using Docker Compose is nice and easy, but because runners are temporary you don't get any caching.

### Demo 2 - Docker's GitHub actions

Docker have their own GitHub actions which support caching image layers.

[ecs-c2-v2.yml](../../.github/workflows/ecs-c2-v2.yml):

* Docker build & push
* buildx configuration
* build cache

The v2 workflow uses a job for each image. There's a lot of duplication in the spec but it means the jobs can run in parallel.

(There's also a Docker QEMU action which you can use for cross-platform Linux builds).

> Run the build from [actions](https://github.com/sixeyed/ecs/actions).

> Check the tags in the [sixeyed/access-log repo](https://hub.docker.com/repository/docker/sixeyed/access-log/tags?page=1&ordering=last_updated).

### Demo 3 - Deploying to AKS with Helm

The v2 build has caching but a fixed image tag. v3 sets the tag and adds image labels, and then it deploys the app to Kubernetes using Helm.

[ecs-c2-v3.yml](../../.github/workflows/ecs-c2-v3.yml):

* Docker metadata to use GitHub tag as image tag and labels
* connection to AKS cluster
* parameterized deployment with Helm (image tag & port)

Nothing in AKS right now:

```
kubectl get nodes

kubectl get all
```

The workflow is triggered from a tag with a version number:

```
git tag v1.0

git push --tags
```

> Check the build in [actions](https://github.com/sixeyed/ecs/actions); output shows the URL to browse to.

> Check the tags for [sixeyed/access-log](https://hub.docker.com/repository/docker/sixeyed/access-log/tags?page=1&ordering=last_updated).

```
kubectl get pods --show-labels

kubectl describe pod -l app=apod-api
```

> Check the GitHub tag is the image tag.

### Coming next

* ECS-C3: GitOps on Kubernetes with Argo CD
