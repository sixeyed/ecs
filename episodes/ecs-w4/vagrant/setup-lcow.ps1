
# install pre-reqs
Install-WindowsFeature -Name Containers
Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force

# install Docker
Install-Module -Name DockerMsftProvider -Repository PSGallery -Force
Install-Package -Name docker -ProviderName DockerMsftProvider -Force

# enable Hyper-V for isolated containers:
Install-WindowsFeature -Name Hyper-V

# enable experimental mode:
mkdir -p C:\ProgramData\docker\config\
[IO.File]::WriteAllLines('C:\ProgramData\docker\config\daemon.json', '{ "experimental":true }')

# install LCOW:
Invoke-WebRequest -UseBasicParsing -OutFile lcow.zip -uri https://github.com/linuxkit/lcow/releases/download/v4.14.35-v0.3.9/release.zip
Expand-Archive lcow.zip -DestinationPath "$Env:ProgramFiles\Linux Containers\." 
