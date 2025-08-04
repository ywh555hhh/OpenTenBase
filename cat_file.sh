#!/bin/bash

# 定义文件列表
files=(
    ".devcontainer/devcontainer.json"
    ".devcontainer/Dockerfile"
    "pgxc_ctl.conf"
    "docker-compose.yml"
    "entrypoint.sh"
)

# 循环遍历文件并 cat 其内容
for file in "${files[@]}"; do
    if [ -f "$file" ]; then
        echo "--- 内容开始: $file ---"
        cat "$file"
        echo "--- 内容结束: $file ---"
        echo "" # 在每个文件内容后添加一个空行，方便阅读
    else
        echo "警告: 文件 '$file' 不存在，已跳过。"
        echo ""
    fi
done