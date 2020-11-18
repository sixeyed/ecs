## ECS-O3: Containers in Production with Kubernetes

Kubernetes is the most popular container orchestrator because of it's power and portability. 

You can model your apps in Kubernetes and deploy the same specs on the desktop, in the datacentre and on a managed Kubernetes service in the cloud. Get a better deal from another cloud? Just deploy your apps there with no changes and edit your DNS records.

In this episode you'll see how to deploy Kubernetes in lab VMs and run some simple applications. The application specs will include production concerns like healthchecks, resource restrictions and security settings.

> Here's it is on YouTube - [ECS-O3: Containers in Production with Kubernetes](https://youtu.be/KTJUcrYffcA)

### Links

* [Learn Kubernetes in a Month of Lunches](https://www.manning.com/books/learn-kubernetes-in-a-month-of-lunches?utm_source=affiliate&utm_medium=affiliate&a_aid=elton&a_bid=a506ee0d)

* [Kubernetes Pod configuration](https://kubernetes.io/docs/tasks/configure-pod-container/) (links to resource allocation, health probes, affinity and volumes)

* [Kubernetes API docs](v1-18.docs.kubernetes.io/docs/reference/generated/kubernetes-api/v1.18) (v 1.18)


### Pre-reqs

I'm running Linux VMs for the Kubernetes cluster using [Vagrant](https://www.vagrantup.com).

You can set the VMs up with:

```
cd episodes/ecs-o3/vagrant

vagrant up
```

> You can use [Kind](https://kind.sigs.k8s.io) or [k3s](https://k3s.io) to run a simple lightweight lab cluster too.

### Initializing the cluster

The VMs are set up with [setup.sh](./vagrant/setup.sh) which installs Docker and [kubeadm](https://kubernetes.io/docs/reference/setup-tools/kubeadm/), the Kubernetes cluster setup tool. You use it to create a cluster and join nodes, and to upgrade Kubernetes.

_Initialize a new cluster from the control plane VM:_

```
vagrant ssh control

sudo docker version

ls /usr/bin/kube*

sudo kubeadm init --pod-network-cidr="10.244.0.0/16" --service-cidr="10.96.0.0/12" --apiserver-advertise-address=$(cat /tmp/ip.txt)
```

> Copy the `kubeadm join` command from the output

_Set up kubectl:_

```
mkdir ~/.kube

sudo cp /etc/kubernetes/admin.conf ~/.kube/config

sudo chmod +r ~/.kube/config
```

_Confirm the cluster is up:_

```
kubectl get nodes
```

The cluster isn't ready because Kubernetes has a pluggable networking layer, and no network is deployed by default. 

We'll deploy [Flannel](https://github.com/coreos/flannel), one of the main Kubernetes network plugins (the other is [Calico](https://docs.projectcalico.org/getting-started/kubernetes/)).

_Deploy the Flannel network:_

```
cd /ecs-o3

kubectl apply -f kube-flannel.yaml

kubectl -n kube-system wait --for=condition=ContainersReady pod -l k8s-app=kube-dns

kubectl get nodes

sudo docker ps
```

## Joining nodes

Nodes need a container runtime and kubeadm installed. The Vagrant VMs are ready to go.

_Join the first node:_

```
vagrant ssh node

sudo kubeadm join [full command from control]

exit
```

_And the second node:_

```
vagrant ssh node2

sudo kubeadm join [full command from control]

exit
```

_Back on the control plane, check node status:_

```
vagrant ssh control

kubectl get nodes -o wide
```

## Deploying a simple app: the APOD gallery

Kubernetes YAML is quite verbose, because of the multiple abstractions you use to model your apps (networking, compute and storage).

This demo app runs across three components and shows NASA's Astronomy Picture of the Day. We'll deploy the app to its own namespace.

You can define multiple Kubernetes objects in each YAML file - how you set it up is your choice:

* [01-namespace.yaml](./apod/01-namespace.yaml)
* [api.yaml](./apod/api.yaml)
* [log.yaml](./apod/log.yaml)
* [web.yaml](./apod/web.yaml)

_Deploy the specs:_

```
cd /ecs-o3/

kubectl apply -f apod/

kubectl get all -n apod
```

_Wait for the web Pod to be ready:_

```
kubectl wait --for=condition=ContainersReady pod -n apod -l app=apod-web

echo "$(cat /tmp/ip.txt):30000"
```

> Browse to the app

_Check the backend API logs:_

```
kubectl logs  -n apod -l app=apod-api

kubectl logs  -n apod -l app=apod-log
```

## Deploying a production(ish) app: the to-do list

The todo-list application specs add more production concerns like resource limits and health probes.

The database components for the todo-list app are in [db.yaml](./todo-list/db.yaml).

_Deploy the todo-list app:_

```
cd /ecs-o3

kubectl apply -f todo-list/

kubectl get all -n todo-list
```

The [web.yaml](./todo-list/web.yaml) Deployment spec has some more settings - it specifies affinity so the web Pods run on the same node as the database Pods.

_Check the Pod locations:_

```
kubectl get pods -n todo-list -o wide

echo "$(cat /tmp/ip.txt):30020"
```

> Browse and add item

Required affinity is a hard rule which limits the orchestrators ability to scale. The [update/web.yaml](./todo-list/update/web.yaml) spec shifts to preferred affinity.

_Deploy the update and watch it roll out:_

```
kubectl apply -f todo-list/update/

kubectl get pods -n todo-list -o wide --watch
```
### Teardown

Removing a namespace will remove all the components, so you can easily clean the cluster.

_Delete namespaces and leave the Swarm:_

```
kubectl get namespace --show-labels

kubectl delete ns -l ecs=o3
```

Or you can exit the SSH session and delete all the VMs.

_Remove the VMs:_

```
exit

vagrant destroy
```

### Coming next

* [ECS-O4: Containers in Production with Nomad](https://youtu.be/Q7D5ZzOLT58)