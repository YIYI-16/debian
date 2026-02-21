#!/bin/bash

# 配置区域
TARGET_USER="dpanel-worker"
PUBLIC_KEY="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEZU3UwlNOnUuTo7tBM4TsjRMq4bNSXbOax8lWpwXbGe docker"
# 核心加固指令：强制进入 Docker 通信模式，禁用所有转发和伪终端
SSH_PREFIX='command="docker system dial-stdio",no-agent-forwarding,no-port-forwarding,no-pty,no-X11-forwarding'

# 1. 创建用户 (不设置密码，禁用 shell 登录)
if id "$TARGET_USER" &>/dev/null; then
    echo "[!] 用户 $TARGET_USER 已存在，跳过创建。"
else
    echo "[+] 正在创建用户 $TARGET_USER..."
    sudo adduser --disabled-password --gecos "" --shell /usr/sbin/nologin $TARGET_USER
fi

# 2. 将用户加入 docker 组
echo "[+] 授予 Docker 管理权限..."
sudo usermod -aG docker $TARGET_USER

# 3. 配置 SSH 密钥
USER_HOME=$(eval echo ~$TARGET_USER)
SSH_DIR="$USER_HOME/.ssh"

echo "[+] 配置 SSH 授权文件..."
sudo mkdir -p "$SSH_DIR"
echo "$SSH_PREFIX $PUBLIC_KEY" | sudo tee "$SSH_DIR/authorized_keys" > /dev/null

# 4. 设置正确的权限
sudo chown -R $TARGET_USER:$TARGET_USER "$SSH_DIR"
sudo chmod 700 "$SSH_DIR"
sudo chmod 600 "$SSH_DIR/authorized_keys"

echo "-----------------------------------------------"
echo "✅ 配置完成！"
echo "现在你可以在 dPanel 中使用以下信息连接："
echo "SSH 用户: $TARGET_USER"
echo "验证方式: SSH 密钥 (ed25519)"
echo "-----------------------------------------------"
echo "⚠️  安全提醒：由于设置了 no-pty，该用户无法通过常规 SSH 客户端登录 Shell。"
