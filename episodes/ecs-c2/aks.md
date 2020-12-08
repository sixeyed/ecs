
Based on instructions from KIAMOL: https://github.com/sixeyed/kiamol/blob/master/ch01/aks/README.md

## Setup

Create cluster:

```
az group create --name ecs-c2 --location eastus

az aks create -g ecs-c2 -n ecs-c2 --node-count 2 --kubernetes-version 1.18.10

az aks get-credentials -g ecs-c2 -n ecs-c2
```

Get subscription ID from `az account list`, then create SP for GH auth:

```
az ad sp create-for-rbac --name "ecs-c2" --role contributor --scopes /subscriptions/<SUBSCRIPTION-ID>/resourceGroups/ecs-c2 --sdk-auth
```

> Copy the JSON output for your GH secret

## Teardown

```
az group delete --name ecs-c2 
```