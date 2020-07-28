# RabbitMQ Compose Cluster

Simple RabbitMQ cluster using docker-compose with config file peer discovery. 

## Starting Cluster

Start the compose stack with `docker-compose up -d`. Watch the logs to observe the cluster formation. Each RabbitMQ server waits for random time before start 
joining cluster.

## Management Web

Access the management ui with http://127.0.0.1:15672/ using the username and password configured in rabbitmq.config file

## TODO
- Introduce TLS certificates
- Python client for additional management
- Unit tests for cluster