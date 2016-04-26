FROM anapsix/alpine-java:jdk8
MAINTAINER Victor Palma <palma.victor@gmail.com>

ENV KAFKA_VERSION="0.9.0.1" \
    KAFKA_USER="kafka" \
    KAFKA_GROUP="kafka" \
    KAFKA_HOME="/opt/kafka" \
    KAFKA_LOGS="/opt/kafka/logs" \
    KAFKA_JKS_HOME="/opt/jks" \
    KAFKA_DIR="/var/lib/kafka" 


RUN apk --no-cache add curl tar wget && \
    mkdir -p ${KAFKA_DIR}/log /opt && \
    wget -q -O - http://mirrors.gigenet.com/apache/kafka/${KAFKA_VERSION}/kafka_2.11-${KAFKA_VERSION}.tgz | tar -xzf - -C /opt  && \
    mv /opt/kafka_2.11-${KAFKA_VERSION} ${KAFKA_HOME} && \
    addgroup $KAFKA_GROUP && \
    adduser -h ${KAFKA_DIR} -D -s /bin/bash -G ${KAFKA_GROUP} ${KAFKA_USER} && \
    chown -R ${KAFKA_USER}:${KAFKA_GROUP} ${KAFKA_DIR} ${KAFKA_HOME}/

USER ${KAFKA_USER}

WORKDIR ${KAFKA_HOME}

COPY start-kafka.sh ${KAFKA_HOME}/bin/start-kafka.sh

# Expose client port (9092/tcp)
EXPOSE 9092 19092

VOLUME ["${KAFKA_DIR}", "${KAFKA_JKS_HOME}", "${KAFKA_LOGS}"]

ENTRYPOINT ["/bin/bash", "-xe", "${KAFKA_HOME}/bin/start-kafka.sh"]
