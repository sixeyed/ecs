#!/bin/bash

echo '--------'
echo "setup.sh as: $(whoami)"
echo '--------'

# install Docker
curl -fsSL https://get.docker.com | sh

# use Docker without sudo
sudo usermod -aG docker vagrant

# install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/download/1.27.3/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
