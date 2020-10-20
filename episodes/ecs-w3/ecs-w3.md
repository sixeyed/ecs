## ECS-W3: Running Windows Containers in the Cloud with ACI and AKS

Microsoft Azure has multiple options for running Windows containers in the cloud. We'll look at two from opposite ends of the complexity spectrum - Azure Container Instances and Azure Kubernetes Service. 

> Here it is on YouTube - [ECS-W3: Running Windows Containers in the Cloud with ACI and AKS](https://youtu.be/jpG0sBqWfgo)

## Links

* [ACI](https://kubernetes.io/docs/setup/production-environment/windows/intro-windows-in-kubernetes/)

* [AKS](https://kubernetes.io/docs/setup/production-environment/windows/intro-windows-in-kubernetes/)

* Episode 15 of [Learn Docker in a Month of Lunches](https://diamol.net) - [Building Docker images that run anywhere: Linux, Windows, Intel & Arm](https://youtu.be/8TOFoCzie7o)

* [Source code for the .NET PetShop app from 2008](https://github.com/sixeyed/petshopvnext/)

* [Deploying to ACI from Docker](https://docs.docker.com/engine/context/aci-integration/)

### Pre-reqs

You'll need the [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/) to follow along with the Azure Demos.

You'll need the Edge release of [Docker Desktop](https://www.docker.com/products/docker-desktop) to follow the other demos.

You'll also need an Azure account :)

### Demo 1 - Deploying Windows Containers to ACI with the Portal

Open the [ACI blade](https://portal.azure.com#blade/HubsExtension/BrowseResource/resourceType/Microsoft.ContainerInstance%2FcontainerGroups).

Configure a new deployment:

```
Container name: sql-server
Image: docker4dotnet/sql-server:2017
OS type: Windows
Memory (GiB): 2
Number of CPU cores: 1
---
Ports: 1433
DNS name label: sql-ecs-w3
---
Environment: sa_password=DockerCon!!!
```

> Check the deployment - container image will take a while to pull...

It's using a large Server Core image: https://hub.docker.com/r/docker4dotnet/sql-server/tags

### Demo 2 - Deploying Windows Containers to ACI with the Azure CLI

Use the command line to create a container from a Nano Server image
```
az container create `
  -g ecs-w3 --name whoami `
  --image diamol/ch16-whoami --os-type Windows `
  --cpu 1 --memory 1.5 `
  --ports 80 --dns-name-label ecs-w3-2
```

> Browse to portal - SQL container should be running, connect with Sqlectron

> Check the Whoami app at http://ecs-w3-2.eastus.azurecontainer.io


### Demo 3 - Managing ACI containers with the Docker CLI

Create a Docker context to manage ACI containers:

```
docker login azure

docker context create aci ecs-w3  # select RG
```

Switch to the ACU context and check running containers:

```
docker context ls

docker context use ecs-w3

docker ps

docker logs whoami_whoami
```

Create a new container:

```
docker run -d -p 80:80 --name whoami2 diamol/ch16-whoami

docker ps
```

> Check with `curl` - Linux

Try to create a Windows container:

```
docker run -d -p 80:80 --name whoami3 diamol/ch16-whoami:windows-amd64

docker run --help
```

> Fails - ACI integration is in beta

Teardown

```
docker rm -f $(docker ps -aq)

docker compose down --project-name sql-server

docker compose down --project-name whoami
```

> Refresh portal

### Demo 4 - Creating a hybrid Windows-Linux AKS cluster

Open the [AKS blade](https://portal.azure.com#blade/HubsExtension/BrowseResource/resourceType/Microsoft.ContainerService%2FmanagedClusters)

New AKS cluster:

- Add Node pool
- OS=Windows
- Node count
- Node size

Create cluster with `az`:

```
az aks create -g ecs-w3 -n ecs-aks `
 --node-count 2 --kubernetes-version 1.17.11 `
 --load-balancer-sku Standard --network-plugin azure `
 --windows-admin-username kube --windows-admin-password "--generated-password--"
```

Add Windows nodes:

```
az aks nodepool add `
    --resource-group ecs-w3 `
    --cluster-name ecs-aks `
    --os-type Windows `
    --name akswin `
    --node-count 2 `
    --kubernetes-version 1.17.11
```

Get creds:

```
az aks get-credentials --resource-group ecs-w3 --name ecs-aks

kubectl get nodes
```

### Demo 5: Deploying .NET Framework Apps to AKS

The demo app is the .NET 3.5 PetShop from 2008...

> Source code for the app is in [sixeyed/petshopvnext](https://github.com/sixeyed/petshopvnext/tree/dotnetconf2020)

Walk through the YAML specs in `ecs-w3/aks`.

Deploy the Nginx Ingress Controller:

```
kubectl get ns

cd episodes/ecs-w3

kubectl apply -f aks/ingress-controller/

kubectl get pods -n ingress-nginx
```

Deploy the Petshop app:

```
kubectl apply -f aks/petshop/

kubectl get pods -n petshop

kubectl get svc -n ingress-nginx
```

> Browse to the external IP

### Coming next

ECS-W3: Running Windows Containers in the Cloud with ACI and AKS