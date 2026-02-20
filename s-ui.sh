#!/bin/bash

# 定义路径变量
DB_PATH="/usr/local/s-ui/db/s-ui.db"
CERT_BASE_DIR="/root/cert"

# 1. 备份数据库（安全第一）
BACKUP_PATH="${DB_PATH}.bak_$(date +%s)"
cp "$DB_PATH" "$BACKUP_PATH"
echo "✅ 数据库已备份至: $BACKUP_PATH"

# 2. 提取 /root/cert 下的域名目录名
# 使用 find 命令查找深度为 1 的目录，并提取第一个结果作为域名
DOMAIN=$(find "$CERT_BASE_DIR" -mindepth 1 -maxdepth 1 -type d -printf "%f\n" | head -n 1)

if [ -z "$DOMAIN" ]; then
    echo "❌ 错误：在 $CERT_BASE_DIR 下未找到任何子域名文件夹，请检查目录是否正确。"
    exit 1
fi

echo "🔍 成功提取到子域名: $DOMAIN"

# 3. 构造新的证书和密钥路径
NEW_CERT="${CERT_BASE_DIR}/${DOMAIN}/fullchain.pem"
NEW_KEY="${CERT_BASE_DIR}/${DOMAIN}/privkey.pem"

echo "📄 目标证书路径: $NEW_CERT"
echo "🔑 目标私钥路径: $NEW_KEY"

# 4. 修改 SQLite 数据库中的 setting 表
echo "⚙️  正在将新路径写入 s-ui 数据库..."

sqlite3 "$DB_PATH" "UPDATE settings SET value = '$NEW_CERT' WHERE key = 'webCertFile';"
sqlite3 "$DB_PATH" "UPDATE settings SET value = '$NEW_KEY' WHERE key = 'webKeyFile';"
sqlite3 "$DB_PATH" "UPDATE settings SET value = '$NEW_CERT' WHERE key = 'subCertFile';"
sqlite3 "$DB_PATH" "UPDATE settings SET value = '$NEW_KEY' WHERE key = 'subKeyFile';"

echo "✅ 数据库更新完毕！"

# 5. 重启 s-ui 服务以应用更改
echo "🔄 正在重启 s-ui 服务..."
systemctl restart s-ui

# 检查服务状态
if systemctl is-active --quiet s-ui; then
    echo "🎉 s-ui 已成功重启，新证书配置已生效！"
else
    echo "⚠️ s-ui 重启失败，请使用 'systemctl status s-ui' 检查报错信息。"
fi
