#!/bin/bash

# 1. 获取 /root/cert 下第一个文件夹的名称
# -maxdepth 1 确保只查找当前层级，-type d 仅查找文件夹
FOLDER_NAME=$(find /root/cert -maxdepth 1 -mindepth 1 -type d -exec basename {} \; | head -n 1)

# 2. 判断是否获取到了文件夹名称
if [ -z "$FOLDER_NAME" ]; then
    echo "未在 /root/cert 下找到任何文件夹，跳过上传。"
    exit 0
fi

echo "检测到目标名称为: $FOLDER_NAME"

# 3. 执行上传并重命名
# 格式：rclone copyto [本地路径] [远程名称]:[存储桶名称]/[新文件名]
# 假设你的 rclone 配置名称为 cloud，目标桶名为 s-ui
rclone copyto "/usr/local/s-ui/db/s-ui.db" "cloud:s-ui/${FOLDER_NAME}.db" --progress

if [ $? -eq 0 ]; then
    echo "成功：文件已作为 ${FOLDER_NAME}.db 上传至 Cloudflare R2。"
else
    echo "错误：上传失败，请检查 Rclone 配置或网络连接。"
fi
