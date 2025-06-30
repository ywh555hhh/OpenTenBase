# Plan A - 终极决战版 Dockerfile
FROM --platform=linux/amd64 ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc make libreadline-dev zlib1g-dev libssl-dev libossp-uuid-dev \
    bison flex git gdb universal-ctags vim sudo openssh-server \
    && rm -rf /var/lib/apt/lists/*

# 创建 opentenbase 用户
RUN useradd -d /data/opentenbase -s /bin/bash -m opentenbase && \
    echo "opentenbase:opentenbase" | chpasswd

# 创建所有需要的目录，但先不改变所有权
RUN mkdir -p /data/project && \
    mkdir -p /data/nodes

# 配置 SSH 服务
RUN mkdir -p /var/run/sshd

WORKDIR /data/project/OpenTenBase
EXPOSE 30004