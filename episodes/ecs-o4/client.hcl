log_level = "DEBUG"
data_dir   = "/etc/nomad.d"

client {
    enabled = true

    # hardcoded server list needed if not using Consul
    # servers = ["<SERVER-IP>:4647"]
}