# 使用一个超轻量的 Alpine Linux 镜像
FROM alpine:3.18

# 安装 dante-server (一个稳定且强大的 SOCKS 服务器)
RUN apk add --no-cache dante-server linux-pam-dev

# 复制我们的配置文件
COPY danted.conf /etc/danted.conf

# 复制我们的启动脚本
COPY entrypoint.sh /entrypoint.sh
# 给予启动脚本执行权限
RUN chmod +x /entrypoint.sh

# 暴露 1080 端口，便于本地和传统部署
EXPOSE 1080

# 健康检查：确认 Socks 端口已经开始监听
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 CMD ["sh", "-c", "port=\"${PORT:-${SOCKS_PORT:-1080}}\"; nc -z 127.0.0.1 \"$port\""]

# 容器启动时运行启动脚本
ENTRYPOINT ["/entrypoint.sh"]
