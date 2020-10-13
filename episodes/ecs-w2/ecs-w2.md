## ECS-W2: Building and Running Windows Apps in Docker Containers

You can package pretty much any Windows app into a Docker image, provided you can install and configure it unattended (there's no UI in Windows containers). 

This episode shows you how to package apps from MSIs and from .NET source code.

> Here it is on YouTube - [ECS-W2: Building and Running Windows Apps in Docker Containers](https://youtu.be/ylYke4A1frw)

## Links

* [.NET Framework base images](https://kubernetes.io/docs/setup/production-environment/windows/intro-windows-in-kubernetes/)

* [.NET Core base images](https://kubernetes.io/docs/setup/production-environment/windows/intro-windows-in-kubernetes/)

* [Docker for .NET Apps](https://github.com/sixeyed/docker4.net) - material from the Udemy course, coming soon :)

* Episode 03 of [DIAMOL](https://diamol.net), [packaging apps from source code into Docker images](https://youtu.be/51okXVJvSNw)

### Pre-reqs

You can follow along with the demos using [Docker Desktop](https://www.docker.com/products/docker-desktop) on Windows 10.

Then clone the [sixeyed/docker4.net](https://github.com/sixeyed/docker4.net) repo for the examples.

### Demo 1 - Navigating Microsoft's Windows images

There are two base OS images:

- [Windows Server Core](https://hub.docker.com/_/microsoft-windows-servercore) - pretty much all of Windows Server, minus the UI
- [Nano Server](https://hub.docker.com/_/microsoft-windows-nanoserver) - a minimal OS without the full Windows API (no 32-bit or .NET Fx support)

> All Microsoft's images are published on MCR but discovery is still on Docker Hub

Check out Windows Server Core:

```
docker image ls mcr.microsoft.com/windows/servercore:*

docker container run -it mcr.microsoft.com/windows/servercore:ltsc2019 
```

Server Core has PowerShell and .NET installed:

```
powershell

Get-WindowsFeature

exit

exit
```

Nano Server just has the Windows command line:

```
docker image ls  mcr.microsoft.com/windows/nanoserver:*

docker container run -it mcr.microsoft.com/windows/nanoserver:2004

dir

type License.txt

exit
```

### Packaging Apps from Existing Artifacts

Using the [sixeyed/docker4.net](https://github.com/sixeyed/docker4.net) repo.

This [Dockerfile](https://github.com/sixeyed/docker4.net/blob/master/docker/02-02-packaging-pre-built-apps/signup-web/v1/Dockerfile) packages an MSI onto the ASP.NET 4.8 base image.

```
cd $env:docker4dotnet  # points to the docker4.net root

cd docker/02-02-packaging-pre-built-apps/signup-web/v1

docker image build -t signup-web:02-01 --no-cache .

docker run -d -p 8080:80 --name web signup-web:02-01
```

> Browse to the app at http://localhost:8080/signup - it doesn't work :)

### Packaging .NET Framework Apps from Source

This [Dockerfile](https://github.com/sixeyed/docker4.net/blob/master/docker/02-03-packaging-netfx-apps/signup-web/v3/Dockerfile) packages the same app from the source code - using the .NET SDK image and the ASP.NET image.

```
cd $env:docker4dotnet

docker image build -t signup-web:02-03 `
  -f ./docker/02-03-packaging-netfx-apps/signup-web/v3/Dockerfile --no-cache .
```

Run the app with SQL Server:

```
docker run -d --name SIGNUP-DB-DEV01 `
  --env sa_password=DockerCon!!! `
  docker4dotnet/sql-server:2017

docker run -d -p 8081:80 --name signup-web signup-web:02-03
```

> Browse to the app at http://localhost:8081/app - now it works :)

### Packaging .NET Core Apps from Source

Same approach for .NET Core (and .NET 5), just different base images and SDK commands.

See [this .NET Core API Dockerfile](https://github.com/sixeyed/docker4.net/blob/master/docker/02-05-packaging-dotnet-apps/reference-data-api/Dockerfile).

Build in the same way:

```
docker image build -t reference-data-api `
  -f ./docker/02-05-packaging-dotnet-apps/reference-data-api/Dockerfile --no-cache .
```

Run with config:

```
docker run -d -p 8082:80 --name api `
  -e ConnectionStrings:SignUpDb="Server=SIGNUP-DB-DEV01;Database=SignUp;User Id=sa;Password=DockerCon!!!;" `
  reference-data-api

curl http://localhost:8082/api/roles
```

### Not All Platforms Are Equal

.NET Core is container-friendly by default:

```
docker logs api

docker top api
```

You need to do some more work for .NET Framework:

```
docker logs signup-web

docker top signup-web
```

### Multi-stage Builds are Super Portable

You don't need a CI server with any SDK tools - you just need Docker.

GitHub actions will build images like this using [a simple workflow](https://github.com/sixeyed/docker4.net/blob/master/.github/workflows/images-windows.yaml).

### Coming next

ECS-W3: Running Windows Containers in the Cloud with ACI and AKS