# syntax=docker/dockerfile:1-labs

#FROM --platform=linux/arm/v7 navikey/raspbian-bullseye:latest AS base
#FROM --platform=linux/arm/v7 mfiscus/raspberrypios:bullseye AS base
FROM --platform=linux/arm/v7 ubuntu:latest AS base

ENV TERM="xterm" LANG="C.UTF-8" LC_ALL="C.UTF-8" TZ="UTC"
ARG MMDVM_HS_INST_DIR="/src/MMDVM_HS" TYPE="MMDVM_HS_Hat"

# install dependencies
RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections && \
    apt update && \
    apt upgrade -y && \
    apt install -y \
        build-essential \
        gcc-arm-none-eabi \
        gdb-arm-none-eabi \
        git \
        libstdc++-arm-none-eabi-newlib \
        libnewlib-arm-none-eabi \
        vim

# Setup directories
RUN mkdir -p ${MMDVM_HS_INST_DIR}

# Clone MMDVM_HS repository
Add --keep-git-dir=true https://github.com/g4klx/MMDVM_HS.git#master ${MMDVM_HS_INST_DIR}

# Copy in source code (use local sources if repositories go down)
#COPY src/ /

# Compile and install MMDVM_HS
RUN cd ${MMDVM_HS_INST_DIR} && \
    cp configs/${TYPE}.h ./Config.h && \
    make


ENTRYPOINT \
    mkdir -p /artifacts && \
    cp -v /src/MMDVM_HS/bin/* /artifacts/