## ECS-C3: GitOps with Kubernetes and Argo

GitOps inverts the Continuous Deployment model. Your production environment watches a Git repo for changes. When there's a new deployment, the production cluster pulls those changes in. 

It's an approach which is becoming very popular. It reduces the number of systems involved in deployment, helps to keep your production environment secure and ensures your entire setup is reproducible.

In this episode we'll see how GitOps works, using Argo - a CNCF project - to deploy to a Kubernetes cluster running in Azure.

> Here it is on YouTube - [ECS-C3: GitOps with Kubernetes and Argo](https://youtu.be/e3oRY_OCoF0)

### Links

* [gitops.tech](https://www.gitops.tech) - the essence of GitOps

* [ArgoCD getting started guide](https://argoproj.github.io/argo-cd/getting_started/)

* [Preparing Docker Apps for Production](https://pluralsight.pxf.io/BqnNJ) - my latest Pluralsight course


### Pre-reqs

Docker Desktop for the local demos; Azure and GitHub for the others.

### Prep for full demo

_Create a whole new Kubernetes cluster with Argo deployed and the APOD app setup:_

https://github.com/sixeyed/apod-infra/actions?query=workflow%3A%22APOD+Infra+-+Create+AKS+Cluster%22

> Trigger workflow (takes a few minutes).

### Demo 1 - install ArgoCD

Install the [Argo CLI](https://argoproj.github.io/argo-cd/cli_installation/).

_Download the CLI for Windows:_

```
curl -sSL -o C:/usr/local/bin/argocd.exe https://github.com/argoproj/argo-cd/releases/download/v1.8.1/argocd-windows-amd64.exe

argocd version
```

_Deploy Argo CD:_

```
kubectl create namespace argocd

kubectl apply -n argocd -f argo/

kubectl get crd -n argocd 
```

_Get the initial server password (which is in the Pod name):_

```
kubectl get pods -n argocd -l app.kubernetes.io/name=argocd-server -o jsonpath='{.items[0].metadata.name}'

$pwd=$(kubectl get pods -n argocd -l app.kubernetes.io/name=argocd-server -o jsonpath='{.items[0].metadata.name}')

argocd login localhost --insecure --username admin --password $pwd
```

_Connect Argo CLI to Kubernetes cluster:_

```
argocd cluster add docker-desktop

kubectl describe clusterrole argocd-manager-role -n kube-system
```

> Check the Argo CD UI at http://localhost, sign in with `admin` and `echo $pwd`

## Demo 2 - deploy an app in Argo CD

_Create the app:_

```
argocd app create apod `
 --repo https://github.com/sixeyed/ecs.git `
 --path episodes/ecs-c3/apod `
 --dest-server https://kubernetes.default.svc `
 --dest-namespace apod

kubectl get ns

argocd app get apod

kubectl get applications -n argocd
```

> Check the app at https://localhost/applications/apod

_Sync the app:_

```
argocd app sync apod

kubectl create ns apod

argocd app sync apod
```

> Check in Argo UI and app at http://localhost:8010/


_Set sync to automatic:_

```
argocd app set apod --sync-policy automated
```

_Update the API spec:_

Edit the replica count in [apod/api.yaml](./episodes/ecs-c3/apod/api.yaml).

```
kubectl get rs -n apod -l app=apod-api

git add apod/api.yaml; git commit -m 'Replica update'; git push
```

> Refresh app in Argo CD UI https://localhost/applications/apod

_Check the changes are synced:_

```
kubectl get rs -n apod -l app=apod-api --watch
```

## Demo 3 - the full GitOps scenario

Multiple Git repos for the full setup:

* [sixeyed/apod-infra](https://github.com/sixeyed/apod-infra) - cluster deployment with Argo setup for sync; manual workflow

* [sixeyed/apod-app](https://github.com/sixeyed/apod-app) - Kustomize model, source for argo; dispatchable workflow to update image tags

* [sixeyed/apod-source](https://github.com/sixeyed/apod-source) - app source code; release workflow to build & push images, and trigger tag update in `sixeyed/apod-app`

> Each repo has secrets for the bits it needs

_Check the whole new Kubernetes cluster:_

https://github.com/sixeyed/apod-infra/actions?query=workflow%3A%22APOD+Infra+-+Create+AKS+Cluster%22

> Check out [apod-aks-create.yml](https://github.com/sixeyed/apod-infra/blob/main/.github/workflows/apod-aks-create.yml), which does the work.

When done, check the output to get the Argo UI info. Browse to get the app IP address.

_Make an ops change - update the replica count:_

Push the change in `sixeyed/apod-app`, check Argo.

```
git commit -m 'Bump replicas'; git push
```

_Make an app change - update the web page title:_

Push the change in `sixeyed/apod-source`, and tag.

```
git commit -m 'Change title'; git push

git tag v3.0; git push --tags
```

> Check in source repo: https://github.com/sixeyed/apod-source/actions

> Check in app repo: https://github.com/sixeyed/apod-app/actions

> Check in Argo UI

> Check app

### Coming next

That's it for 2020 :)

The next show will be in January, where the theme is **observability**.