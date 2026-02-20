#!/bin/bash

# 确保以 root 权限运行
if [ "$EUID" -ne 0 ]; then 
  echo "请使用 root 权限运行此脚本"
  exit
fi

# 1. 询问并修改 Hostname
read -p "请输入新的 Hostname (直接回车则跳过): " NEW_HOSTNAME
if [ -n "$NEW_HOSTNAME" ]; then
    echo "正在将主机名修改为: $NEW_HOSTNAME"
    hostnamectl set-hostname "$NEW_HOSTNAME"
    # 更新 /etc/hosts 文件中的旧主机名为新主机名
    sed -i "s/127.0.1.1.*/127.0.1.1 $NEW_HOSTNAME/g" /etc/hosts
else
    echo "跳过修改主机名。"
fi

# 2. 修改 SSH 端口为 63606
echo "正在将 SSH 端口改为 63606..."
sed -i 's/^#\?Port .*/Port 63606/' /etc/ssh/sshd_config
# 确保密码登录和公钥登录配置正常（可选，但建议保留）
sed -i 's/^#\?PubkeyAuthentication .*/PubkeyAuthentication yes/' /etc/ssh/sshd_config

# 3. 修改 root 密码
echo "正在修改 root 密码..."
echo "root:Tv~%2#1a:ghd.2gCT0" | chpasswd
echo "root 密码已更新。"

# 4. 创建 zhou 用户并配置免密 sudo 及 SSH Key
if id "zhou" &>/dev/null; then
    echo "用户 zhou 已存在，跳过创建步骤。"
else
    echo "正在创建 zhou 用户..."
    useradd -m -s /bin/bash zhou
    # 锁定 zhou 用户的密码（使其无法通过密码登录）
    passwd -d zhou
    
    # 配置免密 sudo
    echo "zhou ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/zhou
    chmod 440 /etc/sudoers.d/zhou

    # 配置 SSH Key
    USER_HOME="/home/zhou"
    mkdir -p "$USER_HOME/.ssh"
    echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKsu5eSItz3zcLrNvugYNf0gzIOVYQv+mQchurA+YpHW zhou" > "$USER_HOME/.ssh/authorized_keys"
    chown -R zhou:zhou "$USER_HOME/.ssh"
    chmod 700 "$USER_HOME/.ssh"
    chmod 600 "$USER_HOME/.ssh/authorized_keys"
    echo "zhou 用户配置完成，已注入 SSH 公钥。"
fi

# 5. 安装并配置 fail2ban
echo "正在安装 fail2ban..."
apt-get update && apt-get install -y fail2ban

# 创建基础配置，防止 SSH 暴力破解
cat > /etc/fail2ban/jail.local <<EOF
[DEFAULT]
bantime  = 1h
findtime = 10m
maxretry = 5

[sshd]
enabled = true
port    = 63606
logpath = %(sshd_log)s
backend = %(sshd_backend)s
EOF

systemctl restart fail2ban
systemctl enable fail2ban
echo "fail2ban 已安装并针对端口 63606 完成配置。"

# 重启 SSH 服务以应用更改
echo "正在重启 SSH 服务..."
systemctl restart ssh

echo "------------------------------------------------"
echo "全部配置完成！"
echo "请注意：下次请使用 ssh -p 63606 zhou@<IP> 登录"
echo "------------------------------------------------"
