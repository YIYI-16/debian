#!/bin/bash

# ================= 配置区域 =================
TARGET_USER="dpanel-worker"
PUBLIC_KEY="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEZU3UwlNOnUuTo7tBM4TsjRMq4bNSXbOax8lWpwXbGe docker"

# 安全前缀：禁用转发、禁用伪终端（无法打开交互窗口），但允许执行 Docker 命令
SSH_PREFIX="no-agent-forwarding,no-port-forwarding,no-pty,no-X11-forwarding"
# ===========================================

# 1. 创建用户（使用 bash 以支持面板的非交互式命令执行）
if id "$TARGET_USER" &>/dev/null; then
    echo "[!] 用户 $TARGET_USER 已存在，正在更新配置..."
    sudo usermod -s /bin/bash "$TARGET_USER"
else
    echo "[+] 正在创建用户 $TARGET_USER..."
    sudo adduser --disabled-password --gecos "" --shell /bin/bash "$TARGET_USER"
fi

# 2. 授予 Docker 管理权限
echo "[+] 授予 Docker 管理权限..."
sudo usermod -aG docker "$TARGET_USER"

# 3. 配置 SSH 授权文件
USER_HOME=$(eval echo ~$TARGET_USER)
SSH_DIR="$USER_HOME/.ssh"

echo "[+] 配置 SSH 授权文件并添加安全限制..."
sudo mkdir -p "$SSH_DIR"
# 写入包含安全前缀的公钥
echo "$SSH_PREFIX $PUBLIC_KEY" | sudo tee "$SSH_DIR/authorized_keys" > /dev/null

# 4. 严格权限设置
sudo chown -R "$TARGET_USER:$TARGET_USER" "$SSH_DIR"
sudo chmod 700 "$SSH_DIR"
sudo chmod 600 "$SSH_DIR/authorized_keys"

echo "-----------------------------------------------"
echo "✅ 配置成功！"
echo "当前安全策略："
echo "1. 权限隔离：该用户非 root，仅可操作 Docker。"
echo "2. 行为锁定：禁止打开交互式 Shell (no-pty)。"
echo "3. 隧道禁用：禁止端口转发，防止内网被渗透。"
echo "-----------------------------------------------"
