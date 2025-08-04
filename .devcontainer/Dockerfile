# 使用和你的 WSL 一样的 Ubuntu 22.04 版本
FROM ubuntu:22.04

# 设置为非交互模式，避免安装过程中断
ENV DEBIAN_FRONTEND=noninteractive

# 核心优化：将官方源替换为国内的清华源
RUN sed -i 's/archive.ubuntu.com/mirrors.tuna.tsinghua.edu.cn/g' /etc/apt/sources.list && \
    sed -i 's/security.ubuntu.com/mirrors.tuna.tsinghua.edu.cn/g' /etc/apt/sources.list

# 安装所有编译、调试和开发所需的依赖
# build-essential 包含了 gcc, g++ 和 make
# 新增了 clangd 和 bear
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential libreadline-dev zlib1g-dev \
    libssl-dev libossp-uuid-dev \
    bison flex git gdb cgdb universal-ctags vim sudo openssh-server \
    clangd bear \
    fish \
    lldb \
    htop \
    sysstat \
    man-db \
    && rm -rf /var/lib/apt/lists/*

# 创建 opentenbase 用户，用于运行数据库
RUN useradd -d /data/opentenbase -s /bin/bash -m opentenbase && \
    echo "opentenbase:opentenbase" | chpasswd

# 创建项目需要的目录
RUN mkdir -p /data/project /data/nodes

# 配置 SSH 服务
RUN mkdir -p /var/run/sshd

# 设置工作目录
WORKDIR /data/project/OpenTenBase

# 暴露协调器节点的端口
EXPOSE 30004