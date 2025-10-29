# Railway SOCKS5 Proxy with Dante

使用 Alpine + Dante 构建的轻量 SOCKS5 代理，已经针对 Railway 部署场景做了适配：

- 自动读取 Railway 提供的 `PORT`（回退到 `SOCKS_PORT` 或 1080），无需手动固定端口。
- 通过 `PROXY_USER` / `PROXY_PASS` 环境变量创建受密码保护的代理用户，避免裸代理风险。
- 启动时自动探测容器出口 IP/网卡并写入 `danted.conf`。
- 内置健康检查，确保端口监听后才报告健康。

## 环境变量

| 名称 | 必填 | 默认值 | 说明 |
| --- | --- | --- | --- |
| `PROXY_USER` | ✅ | — | SOCKS5 认证用户名 |
| `PROXY_PASS` | ✅ | — | SOCKS5 认证密码 |
| `SOCKS_PORT` | ❌ | 1080 | 非 Railway 场景下的监听端口；Railway 会自动注入 `PORT` |

> Railway 将在运行时注入 `PORT` 变量，本镜像会优先使用 `PORT`，当 `PORT` 缺失时回退到 `SOCKS_PORT`，最后回退到 1080。

## Railway 部署指南

### 方式一：使用已有 Registry 镜像
1. 在 Railway 控制台点击 **New → Deploy Docker Image**。
2. 填写镜像地址，例如 `ghcr.io/<your-org>/railway-socks5:latest` 或你自己的仓库地址。
3. 在 **Variables** 中新增：
   - `PROXY_USER`
   - `PROXY_PASS`
4. 点击 **Deploy**，Railway 会自动提供 `PORT`，镜像将监听该端口。
5. 部署完成后，记录服务的域名或公网地址用于代理连接。

### 方式二：从源码构建
1. Fork 或直接导入本仓库。
2. 在 Railway 控制台点击 **New → GitHub Repo**，选择本项目并创建服务。
3. Railway 会自动检测 `Dockerfile` 并构建镜像。
4. 在 **Variables** 中配置 `PROXY_USER` 与 `PROXY_PASS`（可选地设置 `SOCKS_PORT`）。
5. 发布后使用上一步的地址进行代理访问。

## 连通性测试

在任何可以访问该代理的终端执行：

```bash
curl --socks5-user "$PROXY_USER:$PROXY_PASS" --socks5 <proxy-host>:<proxy-port> https://ifconfig.me
```

看到返回的公网 IP 后即表示代理工作正常。

## 本地或其他平台运行

### 直接运行镜像

```bash
docker run -d --name socks5 \
  -e PROXY_USER=myuser \
  -e PROXY_PASS=mypass \
  -p 1080:1080 \
  ghcr.io/<your-org>/railway-socks5:latest
```

### 从源码构建

```bash
docker build -t railway-socks5 .
docker run -d --name socks5 \
  -e PROXY_USER=myuser \
  -e PROXY_PASS=mypass \
  -e SOCKS_PORT=1080 \
  -p 1080:1080 \
  railway-socks5
```

依旧可以使用上面的 `curl` 命令验证连通性。如果需要修改监听端口，请同时调整 `-p` 与 `SOCKS_PORT` 的值。
