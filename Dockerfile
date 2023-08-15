# syntax=docker/dockerfile:1-labs

FROM --platform=linux/arm/v7 ubuntu:latest AS base

ARG MMDVM_HS_INST_DIR="/src/MMDVM_HS" TYPE
ENV TYPE ${TYPE}

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
ADD --keep-git-dir=true https://github.com/g4klx/MMDVM_HS.git#master ${MMDVM_HS_INST_DIR}

# Compile and install MMDVM_HS
RUN cd ${MMDVM_HS_INST_DIR} && \
    cp configs/${TYPE}.h ./Config.h && \
    make

ENTRYPOINT \
    mkdir -p /artifacts && \
    cp -v /src/MMDVM_HS/bin/mmdvm_*.bin /artifacts/${TYPE}.bin