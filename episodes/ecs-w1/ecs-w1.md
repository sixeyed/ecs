## ECS-W1: We Need to Talk About Windows Containers

This episode introduces Docker on Windows, talks about how containers are different on Windows and Linux and shows you some typical Windows workloads you can run in containers.

> Here it is on YouTube - [ECS-W1: We Need to Talk About Windows Containers](https://youtu.be/k0uwoQqHgDI)

## Links

* [Windows support in Kubernetes](https://kubernetes.io/docs/setup/production-environment/windows/intro-windows-in-kubernetes/)

* [Docker for .NET Apps](https://docker4.net) - which is a Udemy course, coming soon :)

* Episode 15 of [DIAMOL](https://diamol.net) which covered [multi-architecture Docker images](https://youtu.be/8TOFoCzie7o)

* [Modernizing .NET Apps with Docker](https://pluralsight.pxf.io/56yLj) - on Pluralsight

* [Docker on Windows](https://amzn.to/3d6bFZ6) - the book

* [Learn Docker in a Month of Lunches](https://amzn.to/3iBmpzV) - the other book

### Pre-reqs

You can follow along with the first demo using [Vagrant](https://www.vagrantup.com) - the setup provisions Linux and Windows VMs with Docker installed. You'll need Hyper-V on Windows or VirtualBox on Linux/Mac/Windows to run the VMs.

The rest of the demos use [Docker Desktop](https://www.docker.com/products/docker-desktop) on Windows 10.

### Setup 

From the root of this repo, switch to the Vagrant folder and provision the VMs:

```
cd episodes/ecs-w1/vagrant

vagrant up linux

vagrant up windows
```

The [Linux setup script](vagrant/setup.sh) and the [Windows setup script](vagrant/setup.ps1) install Docker so the machines are ready to use.

### Demo 1 - Comparing Linux and Windows containers

Open two terminal sessions, connecting to the Linux and Windows VMs:

```
vagrant ssh linux

vagrant ssh windows
```

Check the Docker setup in each:

```
docker version
```

Run a simple web server in a Linux container:

```
docker run -d -p 8080:80 diamol/apache:linux-amd64

ps aux
```

> Browse to the VM IP address at port 8080

Try to run the Windows variant:

```
docker run -d -p 8081:80 diamol/apache:windows-amd64

docker pull diamol/apache:windows-amd64
```

> It fails because the runtime OS doesn't match the image OS - see https://hub.docker.com/r/diamol/apache/tags

Switch to the Windows VM and run the Windows variant:

```
docker run -d -p 8080:80 diamol/apache:windows-amd64

Get-Process
```

> Browse to the VM IP address at port 8080

Try to run the Linux variant:

```
docker run -d -p 8081:80 diamol/apache:linux-amd64

docker pull diamol/apache:linux-amd64
```

### Demo 2 - Container modes on Docker Desktop

Docker Desktop runs Windows containers, and it also manages a Linux OS to run Linux containers.

Run a Windows container:

```
docker run -d -p 8080:80 sixeyed/tweet-app
```

Switch to Linux container mode to run the Linux version:

```
docker run -d -p 8081:80 sixeyed/tweet-app:linux
```

> Browse to http://localhost:8080 and http://localhost:8081

Check the running containers:

```
docker ps
```

### Demo 3 - Windows workloads

Windows containers based on Windows Server Core can run pretty much any Windows app. The [huge image size](https://hub.docker.com/r/sixeyed/tweet-app/tags) is the price of backwards compatibility.

Switch to Windows containers and run SQL Server:

```
docker container run -d -p 1433:1433 --name sql `
  --env sa_password=DockerCon!!! `
  docker4dotnet/sql-server:2017
```

And another SQL Server:

```
docker container run -d -p 1434:1433 --name sql2 `
  --env sa_password=DockerCon!!! `
  docker4dotnet/sql-server:2017

docker ps
```

> Connect with a SQL client (like Sqlectron) and run some `CREATE DATABASE` commands

```
docker exec -it sql powershell

cd 'C:\Program Files\Microsoft SQL Server'

ls .\MSSQL14.SQLEXPRESS\MSSQL\data
```

Run a distributed app from a [Docker Compose manifest](docker-compose.yml):

```
cd episodes/ecs-w1/

docker-compose up -d
```

> Browse to http://localhost:8030 and add an item

> Then connect to Postgres on port 5433 and query the `todo` database

### Coming next

ECS-W2: Building and running Windows apps in Docker containers