#!/bin/bash

# Optional ENV variables:
# * ADVERTISED_HOST: the external ip for the container, e.g. `docker-machine ip \`docker-machine active\``
# * ADVERTISED_PORT: the external port for Kafka, e.g. 9092
# * ZK_CHROOT: the zookeeper chroot that's used by Kafka (without / prefix), e.g. "kafka"
# * LOG_RETENTION_HOURS: the minimum age of a log file in hours to be eligible for deletion (default is 168, for 1 week)
# * LOG_RETENTION_BYTES: configure the size at which segments are pruned from the log, (default is 1073741824, for 1GB)
# * NUM_PARTITIONS: configure the default number of log partitions per topic

function add_config_param {
    echo "${1}: ${2}"
    if grep -q ${1} ${KAFKA_HOME}/config/server.properties; then
        sed -r -i "s|(${1})=(.*)|\1=${2}|g" ${KAFKA_HOME}/config/server.properties
    else
        echo "${1}=${2}" >> ${KAFKA_HOME}/config/server.properties
    fi
}

# Set the external host and port
if [ ! -z "${ADVERTISED_HOST}" ]; then
    echo "advertised host: ${ADVERTISED_HOST}"
    sed -r -i "s/#(advertised.host.name)=(.*)/\1=${ADVERTISED_HOST}/g" ${KAFKA_HOME}/config/server.properties
fi
if [ ! -z "${ADVERTISED_PORT}" ]; then
    add_config_param "port" ${ADVERTISED_PORT}
    echo "advertised port: ${ADVERTISED_PORT}"
    sed -r -i "s/#(advertised.port)=(.*)/\1=${ADVERTISED_PORT}/g" ${KAFKA_HOME}/config/server.properties
fi

# Set the log directory for kafka
if [ ! -z "${KAFKA_LOG_DIR}" ]; then
    add_config_param "log.dirs" ${KAFKA_LOG_DIR}
    echo "kafka log directory: ${KAFKA_LOG_DIR}"
    sed -r -i "s|(log\.dirs)=.*|\1=${KAFKA_LOG_DIRS}|g" ${KAFKA_HOME}/config/server.properties
fi

# Set the broker id
if [ ! -z "${KAFKA_BROKER_ID}" ]; then
    add_config_param "broker.id" "-1"
    echo "kafka broker id set to auto generate: -1"
    sed -r -i "s/(broker.id)=(.*)/\1=${KAFKA_BROKER_ID}/g" ${KAFKA_HOME}/config/server.properties
else
    add_config_param "broker.id" "${KAFKA_BROKER_ID}"
    echo "kafka broker id set to: ${KAFKA_BROKER_ID}"
    sed -r -i "s/(broker.id)=(.*)/\1=${KAFKA_BROKER_ID}/g" ${KAFKA_HOME}/config/server.properties
fi

# Set the zookeeper
if [ ! -z "${ZK_HOST}" ]; then
    # configure kafka
    sed -r -i "s/(zookeeper.connect)=(.*)/\1=${ZK_HOST}:${ZK_PORT}\/kafka/g" ${KAFKA_HOME}/config/server.properties
fi

# Allow specification of log retention policies
if [ ! -z "${LOG_RETENTION_HOURS}" ]; then
    echo "log retention hours: ${LOG_RETENTION_HOURS}"
    sed -r -i "s/(log.retention.hours)=(.*)/\1=${LOG_RETENTION_HOURS}/g" ${KAFKA_HOME}/config/server.properties
fi
if [ ! -z "${LOG_RETENTION_BYTES}" ]; then
    echo "log retention bytes: ${LOG_RETENTION_BYTES}"
    sed -r -i "s/#(log.retention.bytes)=(.*)/\1=${LOG_RETENTION_BYTES}/g" ${KAFKA_HOME}/config/server.properties
fi

if [ ! -z "${KAFKA_PRINCIPAL_BUILDER_CLASS}" ]; then
    echo "KAFKA_PRINCIPAL_BUILDER_CLASS: ${KAFKA_PRINCIPAL_BUILDER_CLASS}"
    add_config_param "principal.builder.class" ${KAFKA_PRINCIPAL_BUILDER_CLASS}
fi


# Configure the default number of log partitions per topic
if [ ! -z "${NUM_PARTITIONS}" ]; then
    echo "default number of partition: ${NUM_PARTITIONS}"
    sed -r -i "s/(num.partitions)=(.*)/\1=${NUM_PARTITIONS}/g" ${KAFKA_HOME}/config/server.properties
fi

# Enable/disable auto creation of topics
if [ ! -z "${AUTO_CREATE_TOPICS}" ]; then
    echo "auto.create.topics.enable: ${AUTO_CREATE_TOPICS}"
    echo "auto.create.topics.enable=${AUTO_CREATE_TOPICS}" >> ${KAFKA_HOME}/config/server.properties
fi

## SSL
if [ ! -z "${INTER_BROKER_PROTOCOL}" ]; then
    add_config_param "ssl.client.auth" ${SSL_CLIENT_AUTH}
    add_config_param "security.inter.broker.protocol" ${INTER_BROKER_PROTOCOL}
    add_config_param "ssl.enabled.protocols" ${SSL_ENABLED_PROTOCOLS}
    add_config_param "ssl.cipher.suites" ${SSL_CIPHER_SUITES}
fi

add_config_param "listeners" "PLAINTEXT://:${ADVERTISED_PORT},SSL://:${ADVERTISED_SSL_PORT}"
add_config_param "advertised.listeners" "PLAINTEXT://${ADVERTISED_HOST}:${ADVERTISED_PORT},SSL://${ADVERTISED_HOST}:${ADVERTISED_SSL_PORT}"

# Configure SSL Location
if [ ! -z "${SSL_KEYSTORE_LOCATION}" ]; then
    add_config_param "ssl.keystore.location" ${SSL_KEYSTORE_LOCATION}
    add_config_param "ssl.keystore.password" ${SSL_KEYSTORE_PASSWORD}
fi

# Configure SSL Truststore
if [ ! -z "${SSL_TRUSTSTORE_LOCATION}" ]; then
    add_config_param "ssl.truststore.location" ${SSL_TRUSTSTORE_LOCATION}
    add_config_param "ssl.truststore.password" ${SSL_TRUSTSTORE_PASSWORD}
fi

# Configure auth
if [ ! -z "${SUPER_USERS}" ]; then
    add_config_param "super.users" ${SUPER_USERS}
fi

if [ ! -z "${KAFKA_AUTHORIZER_CLASS_NAME}" ]; then
    add_config_param "authorizer.class.name" ${KAFKA_AUTHORIZER_CLASS_NAME}
else

    add_config_param "authorizer.class.name" "kafka.security.auth.SimpleAclAuthorizer"
fi

if [ ! -z "${KAFKA_ACL_AUTH}" ]; then
    add_config_param "zookeeper.set.acl" "true"

    sed -r -i "s|(log4j.logger.kafka.authorizer.logger)=(.*)|\1=DEBUG, authorizerAppender|g" ${KAFKA_HOME}/config/log4j.properties
fi

# Run Kafka
${KAFKA_HOME}/bin/kafka-server-start.sh ${KAFKA_HOME}/config/server.properties
