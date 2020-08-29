# RabbitMQ Compose Cluster

Simple RabbitMQ cluster using docker-compose with config file peer discovery.

## Architecture

Compose file creates a cluster with following architecture. Currently cluster only container three RabbitMQ nodes.

![cluster-architecture](architecture.svg)

## Starting Cluster

Start the compose stack with `docker-compose up -d`. 

Server `mq01.rabbit.ops` is the primary server when starting. Other servers wait for the mq01 server to complete the start.
RabbitMQ waits random time before joining the cluster with other nodes. However this method is not reliable. So `wait-for.sh` is used to pause other server
startup until primary server start and healthy. 


## Management Web

Access the management ui with http://127.0.0.1:15672/ using the username and password configured in rabbitmq.conf file

## Environment Variables

RabbitMQ server
- `RABBITMQ_ERLANG_COOKIE` Set the cookie for cluster formation. All nodes in the cluster must have same cookie value
- `RABBITMQ_NODE_NAME` Set the node name. This is used when communicating with other nodes
- `RABBITMQ_USE_LONGNAME` Cluster is setup with FQDN and requires setting to true

Wait-for script
- `PRIMARY_SERVER_HOST` Hostname of the primary server. Default is mq01.rabbit.ops
- `PRIMARY_SERVER_PORT` API port for the primary server. Default is 15672
- `PRIMARY_SERVER_USER` Admin user for the primary API server. Defaul is admin
- `PRIMARY_SERVER_PASSWORD` Admin user password for primary API server. Defaul is rabbit

## TODO
- Introduce TLS certificates
- Python client for additional management
- Unit tests for cluster