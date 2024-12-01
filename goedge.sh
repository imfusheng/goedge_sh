#!/bin/bash

# 提高TCP连接限制的Shell脚本

# 检查是否以root身份运行
if [ "$EUID" -ne 0 ]; then
  echo "请以root用户权限运行该脚本。"
  exit 1
fi

echo "设置内核参数..."

# 设置内核参数的临时生效值
sysctl -w net.core.somaxconn=65535
sysctl -w net.ipv4.tcp_max_syn_backlog=8192
sysctl -w fs.file-max=1000000

echo "永久保存内核参数配置..."

# 定义要添加的内核参数
SYSCTL_CONF="/etc/sysctl.conf"
SYSCTL_SETTINGS=(
"net.core.somaxconn = 65535"
"net.ipv4.tcp_max_syn_backlog = 8192"
"fs.file-max = 1000000"
)

# 备份原始的sysctl.conf文件
cp $SYSCTL_CONF ${SYSCTL_CONF}.bak.$(date +%F_%T)

# 添加或更新内核参数配置
for setting in "${SYSCTL_SETTINGS[@]}"; do
  key=$(echo $setting | cut -d'=' -f1 | xargs)
  grep -q "^$key" $SYSCTL_CONF && sed -i "s|^$key.*|$setting|" $SYSCTL_CONF || echo "$setting" >> $SYSCTL_CONF
done

# 使内核参数配置立即生效
sysctl -p

echo "调整文件描述符限制..."

LIMITS_CONF="/etc/security/limits.conf"
LIMITS_SETTINGS=(
"* soft nofile 65535"
"* hard nofile 65535"
)

# 备份原始的limits.conf文件
cp $LIMITS_CONF ${LIMITS_CONF}.bak.$(date +%F_%T)

# 添加或更新文件描述符限制
for setting in "${LIMITS_SETTINGS[@]}"; do
  key=$(echo $setting | awk '{print $1,$2}')
  grep -q "^$key" $LIMITS_CONF && sed -i "s|^$key.*|$setting|" $LIMITS_CONF || echo "$setting" >> $LIMITS_CONF
done

echo "调整当前会话的文件描述符限制..."
ulimit -n 65535

edge-node restart

echo "所有设置已完成，无需重启主机。"
