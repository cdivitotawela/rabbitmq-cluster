#!/usr/bin/env bash
#
# Utility script to generate full set of certificates including CA and intermedate CA
#
# note: script requires bash 4

SCRIPT_HOME=$(dirname $0)

# Application Domain Configuration
DOMAIN='rabbit.ops'
NODES='mq01 mq02 mq03'
LOAD_BALANCER='mq'

KEY_STRENGTH=4096

# Set this to true to create certificates fresh
CLEAN=true

# Root CA configuration
CA_ROOT_HOME=$SCRIPT_HOME/root-ca
CA_ROOT_CNF=$CA_ROOT_HOME/openssl.cnf
CA_ROOT_KEY=$CA_ROOT_HOME/private/ca-root.key.pem
CA_ROOT_CRT=$CA_ROOT_HOME/certs/ca-root.crt.pem
CA_ROOT_VALID_DAYS=7300
CA_ROOT_SERIAL=$CA_ROOT_HOME/serial

# Intermediate CA configuration
CA_INTERMEDIATE_HOME=$SCRIPT_HOME/intermediate-ca
CA_INTERMEDIATE_CNF=$CA_INTERMEDIATE_HOME/openssl.cnf
CA_INTERMEDIATE_KEY=$CA_INTERMEDIATE_HOME/private/ca-intermediate.key.pem
CA_INTERMEDIATE_CSR=$CA_INTERMEDIATE_HOME/certs/ca-intermediate.csr.pem
CA_INTERMEDIATE_CRT=$CA_INTERMEDIATE_HOME/certs/ca-intermediate.crt.pem
CA_INTERMEDIATE_VALID_DAYS=7300
CA_INTERMEDIATE_SERIAL=$CA_INTERMEDIATE_HOME/serial

# Certificates setup
CERT_FOLDER=$SCRIPT_HOME/certs
CERT_CRT_FOLDER=$CERT_FOLDER/crt
CERT_CSR_FOLDER=$CERT_FOLDER/csr
CERT_KEY_FOLDER=$CERT_FOLDER/key
CERT_VALID_DAYS=3600

# Delete the certificate directory
[[ $CLEAN == 'true' ]] && {
  for item in $CA_ROOT_HOME/private  \
              $CA_ROOT_HOME/certs  \
              $CA_ROOT_HOME/newcerts \
              $CA_ROOT_SERIAL \
              $CA_ROOT_HOME/index.txt \
              $CA_INTERMEDIATE_HOME/private \
              $CA_INTERMEDIATE_HOME/certs \
              $CA_INTERMEDIATE_HOME/newcerts \
              $CA_INTERMEDIATE_SERIAL \
              $CA_INTERMEDIATE_HOME/index.txt \
              $CERT_FOLDER
  do
    echo "Deleting $item"
    rm -rf $item
  done
}

###############################################################
# Setup root CA
###############################################################
mkdir -p $CA_ROOT_HOME/{private,certs,newcerts}
touch $CA_ROOT_HOME/index.txt
[[ -f $CA_ROOT_SERIAL ]] || echo 1000 > $CA_ROOT_SERIAL

[[ -f $CA_ROOT_KEY ]] || openssl genrsa -out $CA_ROOT_KEY $KEY_STRENGTH && chmod 400 $CA_ROOT_KEY

[[ -f $CA_ROOT_CRT ]] || openssl req -config $CA_ROOT_CNF \
                                     -key $CA_ROOT_KEY \
                                     -new \
                                     -x509 \
                                     -days $CA_ROOT_VALID_DAYS \
                                     -sha256 \
                                     -extensions v3_ca \
                                     -out $CA_ROOT_CRT <<EOF
AU
Queensland
Brisbane
RabbitMQ
DevOps
RootCA
admin@rabbit.ops
EOF

###############################################################
# Setup intermediate CA
###############################################################
mkdir -p $CA_INTERMEDIATE_HOME/{private,certs,newcerts}
touch $CA_INTERMEDIATE_HOME/index.txt
[[ -f $CA_INTERMEDIATE_SERIAL ]] || echo 1000 > $CA_INTERMEDIATE_SERIAL

[[ -f $CA_INTERMEDIATE_KEY ]] || openssl genrsa -out $CA_INTERMEDIATE_KEY $KEY_STRENGTH && chmod 400 $CA_INTERMEDIATE_KEY

[[ -f $CA_INTERMEDIATE_CRT ]] || openssl req -config $CA_INTERMEDIATE_CNF \
                                             -key $CA_INTERMEDIATE_KEY \
                                             -new \
                                             -sha256 \
                                             -days $CA_INTERMEDIATE_VALID_DAYS \
                                             -out $CA_INTERMEDIATE_CSR <<EOF
AU
Queensland
Brisbane
RabbitMQ
DevOps
IntermediateCA
admin@rabbit.ops
EOF

###############################################################
# Issue and sign intermediate CA certificate
###############################################################
[[ -f $CA_INTERMEDIATE_CRT ]] ||   openssl ca -config $CA_ROOT_CNF \
                                              -extensions v3_intermediate_ca \
                                              -days $CA_INTERMEDIATE_VALID_DAYS \
                                              -in $CA_INTERMEDIATE_CSR \
                                              -notext \
                                              -out $CA_INTERMEDIATE_CRT


###############################################################
# Issue ter-node inserver certificates
###############################################################
mkdir -p $CERT_FOLDER $CERT_CRT_FOLDER $CERT_CSR_FOLDER $CERT_KEY_FOLDER

for node in $NODES
do
  echo "Issue server certificate for node $node"
  key_file=$CERT_KEY_FOLDER/${node}.${DOMAIN}.key.pem
  [[ -f $key_file ]] || openssl genrsa -out $key_file && chmod 400 $key_file

  csr_file=$CERT_CSR_FOLDER/${node}.${DOMAIN}.csr.pem
  crt_file=$CERT_CRT_FOLDER/${node}.${DOMAIN}.crt.pem
  openssl req -config $CA_INTERMEDIATE_CNF \
              -key $key_file \
              -new \
              -sha256 \
              -out $csr_file <<EOF
AU
Queensland
Brisbane
RabbitMQ
DevOps
${node}.${DOMAIN}
admin@rabbit.ops
EOF

  SAN=DNS:${node}.${DOMAIN},DNS:mq.rabbit.ops openssl ca -config $CA_INTERMEDIATE_CNF \
             -extensions server_cert \
             -days $CERT_VALID_DAYS \
             -notext \
             -md sha256 \
             -in $csr_file \
             -out $crt_file

done

###############################################################
# Issue inter-node client certificate
###############################################################
key_file=$CERT_KEY_FOLDER/client.${DOMAIN}.key.pem
csr_file=$CERT_CSR_FOLDER/client.${DOMAIN}.csr.pem
crt_file=$CERT_CRT_FOLDER/client.${DOMAIN}.crt.pem

[[ -f $key_file ]] || openssl genrsa -out $key_file  && chmod 400 $key_file
openssl req -config $CA_INTERMEDIATE_CNF \
            -key $key_file \
            -new \
            -sha256 \
            -out $csr_file <<EOF
AU
Queensland
Brisbane
RabbitMQ
DevOps
client.${DOMAIN}
admin@rabbit.ops
EOF

openssl ca -config $CA_INTERMEDIATE_CNF \
           -extensions usr_cert \
           -days $CERT_VALID_DAYS \
           -notext \
           -md sha256 \
           -in $csr_file \
           -out $crt_file


###############################################################
# Issue management/api certificate
###############################################################
key_file=$CERT_KEY_FOLDER/management.${DOMAIN}.key.pem
csr_file=$CERT_CSR_FOLDER/management.${DOMAIN}.csr.pem
crt_file=$CERT_CRT_FOLDER/management.${DOMAIN}.crt.pem

[[ -f $key_file ]] || openssl genrsa -out $key_file  && chmod 400 $key_file
openssl req -config $CA_INTERMEDIATE_CNF \
            -key $key_file \
            -new \
            -sha256 \
            -out $csr_file <<EOF
AU
Queensland
Brisbane
RabbitMQ
DevOps
management.${DOMAIN}
admin@rabbit.ops
EOF

openssl ca -config $CA_INTERMEDIATE_CNF \
           -extensions mgt_cert \
           -days $CERT_VALID_DAYS \
           -notext \
           -md sha256 \
           -in $csr_file \
           -out $crt_file



###############################################################
# RabbitMQ compose cluster specific setup
###############################################################

# Define the project home folder so generated certificates can be copied to the correct location
PROJECT_HOME=$SCRIPT_HOME/../..

# Copy individual server certs to its own folder
for node in $NODES
do
  mkdir $PROJECT_HOME/config/tls/${node}
  cp -f $CERT_CRT_FOLDER/${node}.${DOMAIN}.crt.pem $PROJECT_HOME/config/tls/${node}/ && chmod 664 $PROJECT_HOME/config/tls/${node}/${node}.${DOMAIN}.crt.pem
  cp -f $CERT_KEY_FOLDER/${node}.${DOMAIN}.key.pem $PROJECT_HOME/config/tls/${node}/ && chmod 664 $PROJECT_HOME/config/tls/${node}/${node}.${DOMAIN}.key.pem
done

# Copy inter-node communication client certs
cp -f $CERT_KEY_FOLDER/client.${DOMAIN}.key.pem $PROJECT_HOME/config/tls/ && chmod 664 $PROJECT_HOME/config/tls/client.${DOMAIN}.key.pem
cp -f $CERT_CRT_FOLDER/client.${DOMAIN}.crt.pem $PROJECT_HOME/config/tls/ && chmod 664 $PROJECT_HOME/config/tls/client.${DOMAIN}.crt.pem

# Copy management/api cert
cp -f $CERT_KEY_FOLDER/management.${DOMAIN}.key.pem $PROJECT_HOME/config/tls/ && chmod 664 $PROJECT_HOME/config/tls/management.${DOMAIN}.key.pem
cp -f $CERT_CRT_FOLDER/management.${DOMAIN}.crt.pem $PROJECT_HOME/config/tls/ && chmod 664 $PROJECT_HOME/config/tls/management.${DOMAIN}.crt.pem

# Copy CA bundle
cat $CA_INTERMEDIATE_CRT $CA_ROOT_CRT > $PROJECT_HOME/config/tls/ca.bundle.pem
