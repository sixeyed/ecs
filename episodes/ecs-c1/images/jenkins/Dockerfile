FROM jenkins/jenkins:2.249.3-lts-alpine

USER root

RUN apk add --no-cache --repository http://dl-cdn.alpinelinux.org/alpine/edge/community \
    docker-cli \
    docker-compose

USER jenkins