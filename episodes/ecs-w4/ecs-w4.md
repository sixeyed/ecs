## ECS-W4: Isolation and Versioning in Windows Containers

Linux containers use features of the operating system which have been supported for a long time - there are no real versioning issues, you can run containers with newer OS versions than the host machine. 

Windows is different and you need to match the major OS version on the host and the container image, or run containers with an additional layer of isolation.

This episode looks at the finer details of Windows OS versions and container isolation modes on Windows Server and Windows 10.

> Here it is on YouTube - [ECS-W4: Isolation and Versioning in Windows Containers](https://youtu.be/6knkAOYZI9U)

### Links

* [Windows OS updates for containers](https://docs.microsoft.com/en-us/virtualization/windowscontainers/deploy-containers/update-containers)

* [Nano Server on Docker Hub](https://hub.docker.com/_/microsoft-windows-nanoserver)

* [Windows Server Core on Docker Hub](https://hub.docker.com/_/microsoft-windows-servercore)

* [Configuring LCOW on Windows Server](https://success.mirantis.com/article/how-to-enable-linux-containers-on-windows-server-2019)

### Pre-reqs

You'll need [Docker Desktop](https://www.docker.com/products/docker-desktop) to follow the Windows 10 demos.

You can follow along with the Windows Server demos using [Vagrant](https://www.vagrantup.com).

Spin up your Windows Server VMs:

```
cd episodes/ecs-w4/vagrant

vagrant up windows

vagrant up lcow
```

### Demo 1 - Isolation Modes for Windows Containers

Default isolation mode is Hyper-V on Docker Desktop:

```
docker run -d --name sql1 dak4dotnet/sql-server:2017

docker inspect sql1 -f '{{.HostConfig.Isolation}}'

docker top sql1

Get-Process sqlservr
```

You can use process isolation on Windows 10:

```
docker run -d --name sql2 --isolation=process dak4dotnet/sql-server:2017

docker ps

docker top sql2

Get-Process sqlservr
```

... but only if the OS version matches the major version the image uses:

```
docker manifest inspect dak4dotnet/sql-server:2017

winver

docker manifest inspect nats

docker run -d --isolation=process nats
```

> See [Windows Server release info for version support matrix](https://docs.microsoft.com/en-us/windows-server/get-started/windows-server-release-info)

### Demo 2 - OS Versions for Base Images

OS version on local machine:

```
$($ProgressPreference = 'SilentlyContinue'; Get-ComputerInfo).OsHardwareAbstractionLayer
```

Nano Server - current and previous versions:

```
docker run mcr.microsoft.com/windows/nanoserver:2004 cmd /C ver

docker run mcr.microsoft.com/windows/nanoserver:1809 cmd /C ver

docker run mcr.microsoft.com/windows/nanoserver:1903 cmd /C ver
```


Nano Server - current and previous versions with process isolation:

```
# this works because my host is currently on 2004:
docker run --isolation=process mcr.microsoft.com/windows/nanoserver:2004 cmd /C ver

# this will fail:
docker run --isolation=process mcr.microsoft.com/windows/nanoserver:1903 cmd /C ver  
```


Nano Server - future version:

```
# this fails too - Hyper-V provides backwards but not forwards compatibility:
docker run mcr.microsoft.com/windows/nanoserver:2009 cmd /C ver

docker manifest inspect mcr.microsoft.com/windows/nanoserver:2009
```

Same with Windows Server Core:

```
docker run --isolation=process mcr.microsoft.com/windows/servercore:2004 cmd /C ver

docker run --isolation=process mcr.microsoft.com/windows/nanoserver:1903 cmd /C ver

docker run --isolation=hyperv mcr.microsoft.com/windows/nanoserver:1903 cmd /C ver

```

> Not forever: https://github.com/microsoft/Windows-Containers/projects/1#card-41037816


## Demo 3 - Isolation Modes on Windows Server

The VM uses LTSC 2019:

```
vagrant ssh windows

powershell

$($ProgressPreference = 'SilentlyContinue'; Get-ComputerInfo).OsHardwareAbstractionLayer
```

Default is process isolation on Windows Server:

```
docker run -d --name sql1 dak4dotnet/sql-server:2017

docker inspect sql1 -f '{{.HostConfig.Isolation}}'

docker top sql1

Get-Process sqlservr
```

You can use hyper-v isolation if the Hyper-V feature is enabled:

```
Get-WindowsFeature

# no Hyper-V feature so this will fail:
docker run -d --name sql2 --isolation=hyperv dak4dotnet/sql-server:2017
```

### Demo 3 - LCOW (Linux Containers on Windows)

**[LCOW](https://github.com/linuxkit/lcow) is no longer actively developed**.

Setup by default on Docker Desktop:

```
docker info
```

Run a Linux Apache container:

```
docker run -d -p 8081:80 --name apache diamol/apache:linux-amd64

docker inspect apache
```

> Browse to http://localhost:8081

Custom install on Windows Server - requires Hyper-V:

```
vagrant ssh lcow

powershell

Get-WindowsFeature
```

Can use Hyper-V isolation now:

```
docker run -d --name sql2 --isolation=hyperv dak4dotnet/sql-server:2017

docker top sql2

Get-Process sqlservr
```

... but not for forward compatibility:

```
docker run -d --name sql3 --isolation=hyperv dak4dotnet/sql-server:2017-1909
```

But it does enable LCOW:

```
docker run -d -p 8081:80 --name apache diamol/apache:linux-amd64

docker inspect apache

ipconfig
```

> Browse to the VM IP address, port `8081`


### Coming next

ECS-O1: Understanding Container Orchestration
