#!/bin/sh

set -eu

PORT="${PORT:-${SOCKS_PORT:-1080}}"
LISTEN_ADDRESS="0.0.0.0"

if [ -z "${PROXY_USER:-}" ] || [ -z "${PROXY_PASS:-}" ]; then
  cat <<'EOF'
错误: 必须设置 PROXY_USER 和 PROXY_PASS 环境变量。
为了避免暴露裸代理，请提供认证信息后重试。
EOF
  exit 1
fi

if ! id "$PROXY_USER" >/dev/null 2>&1; then
  adduser -D -s /bin/false "$PROXY_USER"
  echo "SOCKS5 代理用户 $PROXY_USER 已创建。"
else
  echo "SOCKS5 代理用户 $PROXY_USER 已存在，更新密码。"
fi

echo "$PROXY_USER:$PROXY_PASS" | chpasswd

echo "正在检测容器外网出口信息..."
ROUTE_INFO=$(ip route get 1.1.1.1 2>/dev/null || true)
CONTAINER_IP=$(printf '%s\n' "$ROUTE_INFO" | awk -F'src ' 'NF>1{print $2}' | awk '{print $1}')
CONTAINER_IFACE=$(printf '%s\n' "$ROUTE_INFO" | awk '{for (i=1;i<=NF;i++) if ($i == "dev") {print $(i+1); exit}}')

if [ -z "$CONTAINER_IP" ]; then
  FALLBACK_IP=$(hostname -i 2>/dev/null | awk '{print $1}')
  if [ -n "$FALLBACK_IP" ]; then
    CONTAINER_IP="$FALLBACK_IP"
  fi
fi

EXTERNAL_VALUE="$CONTAINER_IP"
if [ -z "$EXTERNAL_VALUE" ] && [ -n "$CONTAINER_IFACE" ]; then
  EXTERNAL_VALUE="$CONTAINER_IFACE"
fi

if [ -z "$EXTERNAL_VALUE" ]; then
  echo "警告: 无法检测到容器外网出口信息，将使用监听地址 $LISTEN_ADDRESS。"
  EXTERNAL_VALUE="$LISTEN_ADDRESS"
fi

echo "检测到容器出口配置: $EXTERNAL_VALUE"

sed -i "s|__LISTEN_ADDRESS__|$LISTEN_ADDRESS|g" /etc/danted.conf
sed -i "s|__LISTEN_PORT__|$PORT|g" /etc/danted.conf
sed -i "s|__EXTERNAL_BIND__|$EXTERNAL_VALUE|g" /etc/danted.conf

echo "SOCKS5 代理监听地址: ${LISTEN_ADDRESS}:${PORT}"
echo "正在启动 SOCKS5 代理服务..."
exec /usr/sbin/sockd -f /etc/danted.conf -D
