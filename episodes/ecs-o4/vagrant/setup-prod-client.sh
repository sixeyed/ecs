#!/bin/bash

# see https://www.consul.io/docs/agent/options.html

mkdir -p /opt/consul
mkdir -p /etc/consul.d

(
cat <<-EOF
  {
    "datacenter": "dc1",
    "data_dir": "/opt/consul"
  }
EOF
) | sudo tee /etc/consul.d/config.json

