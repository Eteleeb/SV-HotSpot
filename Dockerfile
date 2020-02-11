FROM debian:buster-slim
label maintainer "Abdallah Eteleeb <eteleeb@wustl.edu>"

VOLUME /build

# bootstrap build dependencies
RUN apt-get update -qq \
    && apt-get -y install apt-transport-https \
    && apt-get update -qq \
    && apt-get -y install \
        build-essential \
        git-core \
        libcurl4-openssl-dev \
        curl \
        ca-certificates \
        zlib1g-dev \
        --no-install-recommends

WORKDIR /build


