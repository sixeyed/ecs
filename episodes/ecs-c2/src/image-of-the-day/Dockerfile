FROM maven:3.6.3-jdk-11 AS builder

WORKDIR /usr/src/iotd
COPY pom.xml .
RUN mvn -B dependency:go-offline

COPY . .
RUN mvn package

# config util
FROM maven:3.6.3-jdk-11 as utility-builder

WORKDIR /usr/src/utilities
COPY ./src/utilities/ConfigLoader.java .
RUN javac ConfigLoader.java

# app
FROM openjdk:11-jre-slim

ARG BUILD_NUMBER=0
ARG BUILD_TAG=local
ARG COMMIT_SHA=local

LABEL build_number=${BUILD_NUMBER}
LABEL build_tag=${BUILD_TAG}
LABEL commit_sha=${COMMIT_SHA}

EXPOSE 80
ENV CONFIG_SOURCE_PATH="" \
    CONFIG_TARGET_PATH="/app/config/application.properties"

CMD java ConfigLoader && \
    java -jar /app/iotd-service-0.1.0.jar

WORKDIR /app/config
WORKDIR /app
COPY --from=utility-builder /usr/src/utilities/ConfigLoader.class .
COPY --from=builder /usr/src/iotd/target/iotd-service-0.1.0.jar .