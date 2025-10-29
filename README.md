# my-socks5-proxy

`my-socks5-proxy` is a lightweight Docker image that packages the Dante SOCKS5 server with a simple entrypoint for provisioning proxy credentials at runtime. The image now ships as a multi-architecture build (Linux/amd64 and Linux/arm64) and can be published automatically to Docker Hub and GitHub Container Registry (GHCR).

## Continuous delivery workflow

The repository includes a reusable workflow at `.github/workflows/docker-publish.yml` that builds and publishes container images whenever you:

- push to the `main` branch,
- create a tag that matches the pattern `v*` (for example `v1.2.3`), or
- trigger the workflow manually from the Actions tab.

Each run builds both amd64 and arm64 variants using Docker Buildx with GitHub Actions cache support.

### Configure registry credentials

1. **Docker Hub (optional)**
   - Navigate to Docker Hub → *Account Settings* → *Security* and create a new Access Token.
   - Add the following repository secrets:
     - `DOCKERHUB_USERNAME` – your Docker Hub username.
     - `DOCKERHUB_TOKEN` – the access token created above.

2. **GitHub Container Registry (GHCR)**
   - The workflow logs in to GHCR using the repository owner account.
   - Choose one of the following authentication options:
     - **Personal access token** – create a classic PAT with the `write:packages` scope and store it as the `GHCR_PAT` repository secret.
     - **GITHUB_TOKEN** – alternatively, open *Settings → Actions → General → Workflow permissions* and enable **Read and write** for the `GITHUB_TOKEN`, ensuring the **Packages: write** scope is available.

> ℹ️ The workflow automatically pushes to both registries when credentials are present. If Docker Hub secrets are omitted, the image is only published to GHCR.

### Tagging strategy

- **Pushes to `main`** produce the tags:
  - `latest`
  - `<short-sha>` (e.g., `a1b2c3d`)

- **Annotated tags (`v*`)** produce the tags:
  - `latest`
  - `vX.Y.Z` (matching the Git tag)
  - `<short-sha>`

All tags are emitted for every configured registry, so your downstream deploys can reference the tag style that fits best.

## Pull and run the image

Once a workflow run completes, pull the image from the registry of your choice:

```bash
# Docker Hub
docker pull docker.io/<your-dockerhub-username>/my-socks5-proxy:latest

# GitHub Container Registry
docker pull ghcr.io/<github-owner>/my-socks5-proxy:latest
```

Start the proxy by providing credentials via environment variables:

```bash
docker run \
  -p 1080:1080 \
  -e PROXY_USER=youruser \
  -e PROXY_PASS=yourpass \
  docker.io/<your-dockerhub-username>/my-socks5-proxy:latest
```

Replace the image reference with the registry and tag you prefer. The container listens on port `1080/tcp` by default.

### Deploy from a registry (example: Railway)

1. In Railway, choose **Deploy from Registry** and supply the image, e.g. `docker.io/<your-dockerhub-username>/my-socks5-proxy:latest` or the GHCR equivalent.
2. Set the environment variables `PROXY_USER` and `PROXY_PASS` to your desired credentials.
3. Deploy – no additional build steps are required because the workflow publishes ready-to-run images.

## Multi-architecture availability

The workflow builds with Docker Buildx using QEMU emulation, producing images for both `linux/amd64` and `linux/arm64`. Registry clients automatically pull the correct variant for the target platform.
