#!/bin/bash

# 1. 获取 /root/cert 下第一个文件夹的名称
FOLDER_NAME=$(find /root/cert -maxdepth 1 -mindepth 1 -type d -exec basename {} \; | head -n 1)

# 2. 判断是否获取到了文件夹名称
if [ -z "$FOLDER_NAME" ]; then
    echo "未在 /root/cert 下找到任何文件夹，无法匹配，跳过下载。"
    exit 0
fi

echo "检测到证书文件夹名称为: $FOLDER_NAME"
echo "正在尝试从 R2 匹配文件: ${FOLDER_NAME}.db ..."

# 3. 确保本地目标目录存在
mkdir -p /usr/local/s-ui/db/

# 4. 从 Cloudflare R2 下载并重命名
# 格式：rclone copyto [远程名称]:[存储桶名称]/[云端文件名] [本地路径]
# 假设你的 rclone 配置名称为 cloud，存储桶名为 s-ui
rclone copyto "cloud:s-ui/${FOLDER_NAME}.db" "/usr/local/s-ui/db/s-ui.db" --progress

# 5. 检查结果
if [ $? -eq 0 ]; then
    echo "成功：已将云端 ${FOLDER_NAME}.db 下载并恢复为 /usr/local/s-ui/db/s-ui.db"
    # 如果 s-ui 正在运行，建议重启一下以加载新数据库
    # s-ui restart
else
    echo "错误：下载失败。请确认 R2 存储桶中是否存在 ${FOLDER_NAME}.db"
fi
