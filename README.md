# RabbitMQ Compose Cluster

Simple RabbitMQ cluster using docker-compose with config file peer discovery. 

## Starting Cluster

Start the compose stack with `docker-compose up -d`. Watch the logs to observe the cluster formation. Each RabbitMQ server waits for random time before start 
joining cluster.

## Management Web

Access the management ui with http://127.0.0.1:15672/ using the username and password configured in rabbitmq.conf file

## Problems

When starting the cluster initially there can be a race condition even with random timing when using the peer discovering by config file. Possibly new docker-entry.sh
can be used to control the management of wait times.

## TODO
- Introduce TLS certificates
- Python client for additional management
- Unit tests for cluster

## Cluster Using Multiple Nodes

When a RabbitMQ cluster is setup using docker with multiple VMs then DNS is very important. It is important to set the FQDN in docker hostname so that RabbitMQ
will use the correct domain when trying to reach other nodes. If not RabbitMQ append default localdomain when searching for peers. Following is tested compose file
that can be used to start containers in each node.

Must have FQDN in container hostname. This will configure the domain for the container. Node name will be just hostnames without domain.
```yaml
version: "3"
services:
  rabbitmq:
    image: "rabbitmq:3.8.5-management"
    container_name: "rabbitmq1"
    hostname: "rabbitmq1.mydomain.org"
    environment:
      RABBITMQ_ERLANG_COOKIE: 'cookiemaster'
      RABBITMQ_NODE_NAME: "rabbitmq1"
      RABBITMQ_USE_LONGNAME: 'true'
    ports:
      - '5672:5672'
      - '15672:15672'
      - '4369:4369'
      - '35672-35682':35672-35682
      - '25672:25672'
    volumes:
      - "FILE_ON_HOST:/etc/rabbitmq/rabbitmq.conf"
```

Must have FQDN in peer configuration
```ini
# Disable guest user
loopback_users.guest = false

# Configure admin user
default_user = admin
default_pass = replaceWithStrongPassword
default_user_tags.administrator = true
default_permissions.configure = .*
default_permissions.read = .*
default_permissions.write = .*

# Cluster peer discovery. Use config file.
# This does not require all nodes. Having at least one running node enough.
# Each node wait random time before checking other nodes so its good to have all nodes configured
# for initial cluster
cluster_formation.peer_discovery_backend = classic_config
cluster_formation.classic_config.nodes.1 = rabbit@rabbitmq1.mydomain.org
cluster_formation.classic_config.nodes.1 = rabbit@rabbitmq2.mydomain.org
```