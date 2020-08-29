#!/bin/bash
#
# This script waits for primary RabbitMQ server to start
#
# This useful during the initial cluster creation. Without the script RabbitMQ servers
# may start in their own cluster.
#

PRIMARY_SERVER_HOST=${PRIMARY_SERVER_HOST:-mq01.rabbit.ops}
PRIMARY_SERVER_PORT=${PRIMARY_SERVER_PORT:-15672}
PRIMARY_SERVER_USER=${PRIMARY_SERVER_USER:-admin}
PRIMARY_SERVER_PASSWORD=${PRIMARY_SERVER_PASSWORD:-rabbit}

echo "Starting wait-for script"

# Pre-requisites
echo "Installing packages required for wait script"
{
  apt-get update
  apt-get install -y curl jq
} > /dev/null

RETIRES=12
while [ 1 -eq 1 ]
do
  STATUS=$(curl -s -u ${PRIMARY_SERVER_USER}:${PRIMARY_SERVER_PASSWORD} http://${PRIMARY_SERVER_HOST}:${PRIMARY_SERVER_PORT}/api/healthchecks/node | jq -r '.status')

  # Check primary node started
  if [[ ${STATUS} == 'ok' ]]
  then
    echo "Primary node started. Proceed to start rabbitmq-server"
    break
  fi

  RETIRES=$(( ${RETIRES} - 1 ))
  echo "Primary server not ready. Waiting 10s. Remaining $RETIRES retries"

  # Exit the process
  [[ ${RETIRES} -eq 0 ]] && exit 1

  # Sleep
  sleep 10
done

# Clean added packages
echo "Clean installed packages"
{
  apt-get remove -y curl jq
  apt-get clean
} > /dev/null

# Start server
echo "Hand-over to rabbitmq-server"
exec rabbitmq-server