#!/bin/bash

# ==============================================================================
#  我的个人开发环境初始化脚本
#
#  使用方法: 在一个全新的容器中，以 ROOT 用户身份运行此脚本一次。
#           它将会为 'root' 和 'opentenbase' 两个用户完成个性化配置。
# ==============================================================================

# 如果任何命令执行失败，则立即退出脚本
set -e

echo "🚀 开始为【root】和【opentenbase】用户进行个性化环境配置..."

# --- 阶段一: 系统级准备 (以 root 身份运行) ---

echo "🔧 [阶段 1/3] 系统准备与工具安装..."

# 步骤 1.1: 关键步骤 - 首先移除 Git 代理设置！
# 确保后续需要使用 Git 的命令 (如克隆 Oh My Bash) 能够正常工作。
echo "  - 正在清空全局 Git 代理..."
git config --global --unset-all http.proxy || echo "提示: 全局 http 代理未曾设置。"
git config --global --unset-all https.proxy || echo "提示: 全局 https 代理未曾设置。"

# 步骤 1.2: 更新 apt 软件源并安装个人常用工具
echo "  - 正在更新软件源并安装 wget, curl..."
apt-get update
apt-get install -y wget curl

echo "✅ [阶段 1/3] 系统准备完成。"

# --- 阶段二: 为 'root' 用户进行配置 ---

echo "👤 [阶段 2/3] 正在为【root】用户进行配置..."

# 步骤 2.1: 为 root 安装 Oh My Bash
if [ ! -d "/root/.oh-my-bash" ]; then
    echo "  - 正在为 root 安装 Oh My Bash..."
    # 修正：移除了 '--unattended' 参数。安装脚本在非交互式 shell 中通常会自动处理。
    bash -c "$(curl -fsSL https://raw.githubusercontent.com/ohmybash/oh-my-bash/master/tools/install.sh)" "" --unattended
else
    echo "  - Oh My Bash 已为 root 安装，跳过。"
fi

# 步骤 2.2: 设置 root 用户的个人 Git 信息
echo "  - 正在为 root 设置个人 Git 信息..."
git config --global user.name "ywh"
git config --global user.email "1916647616@qq.com"

echo "✅ [阶段 2/3] 【root】用户配置完成。"


# --- 阶段三: 为 'opentenbase' 用户进行配置 ---

echo "👤 [阶段 3/3] 正在为【opentenbase】用户进行配置..."

# 步骤 3.1: 为 opentenbase 安装 Oh My Bash
if [ ! -d "/data/opentenbase/.oh-my-bash" ]; then
    echo "  - 正在为 opentenbase 安装 Oh My Bash..."
    # 重要: 我们必须以 'opentenbase' 用户的身份来执行此命令。
    # 'sudo -H -u <用户>' 命令是完成此任务的完美工具。-H 参数可以确保家目录设置正确。
    sudo -H -u opentenbase bash -c "$(curl -fsSL https://raw.githubusercontent.com/ohmybash/oh-my-bash/master/tools/install.sh)" "" --unattended
else
    echo "  - Oh My Bash 已为 opentenbase 安装，跳过。"
fi

echo "✅ [阶段 3/3] 【opentenbase】用户配置完成。"

echo "🎉 太棒了！所有配置均已完成。请开启一个新的 shell 来体验变化 (例如: exit 退出容器后重新进入)。"