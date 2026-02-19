#!/bin/bash
# 自动安装并配置 Rclone
curl https://rclone.org/install.sh | sudo bash

mkdir -p ~/.config/rclone/

cat <<EOF > ~/.config/rclone/rclone.conf
[cloud]
type = s3
provider = Cloudflare
access_key_id = c6dfdd44a75eae3560cabb1970104dbc
secret_access_key = 6c258b37390e9967ee4dce43f2c8ee998a54fa641e091ba874cb731b166ed3d1
endpoint = https://6a638c3c2047a3ce064af7e4febb0ead.r2.cloudflarestorage.com
acl = private
EOF

echo "Rclone 配置完成！"
