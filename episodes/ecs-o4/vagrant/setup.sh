#!/bin/bash

# install Docker
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker vagrant

# install Nomad
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
apt-get update && apt-get install nomad