# Deployment Guide

1. Provision an Ubuntu 22.04+ VPS and point your DNS `A` record for `example.com` to the server's public IP. Wait until DNS resolves before requesting a real certificate.
2. Install Docker Engine and the Compose plugin:

   ```bash
   sudo apt-get update
   sudo apt-get install -y ca-certificates curl gnupg
   sudo install -m 0755 -d /etc/apt/keyrings
   curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
   echo \
     "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
     $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
     sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
   sudo apt-get update
   sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
   sudo usermod -aG docker "$USER"
   newgrp docker
   ```

3. Clone the repository onto the server and move into the Docker deployment folder:

   ```bash
   git clone https://github.com/TonyMckes/conduit-realworld-example-app.git
   cd conduit-realworld-example-app/docker
   ```

4. Create the deployment env file:

   ```bash
   cp .env.example .env
   ```

   Update `DOMAIN`, `CERTBOT_EMAIL`, and any non-secret settings before continuing.

5. Create file-based secrets and lock down their permissions:

   ```bash
   mkdir -p secrets
   openssl rand -base64 48 > secrets/postgres_password.txt
   openssl rand -base64 64 > secrets/jwt_key.txt
   chmod 600 secrets/postgres_password.txt secrets/jwt_key.txt
   ```

   This stack mounts those files as Docker secrets so the database password and JWT signing key are not passed as plain environment variables.

6. If you want local parity or need to smoke-test before public DNS is ready, set `SSL_MODE=self-signed` in `docker/.env`. That mode generates a self-signed certificate inside the shared certificate volume. Switch back to `SSL_MODE=letsencrypt` once DNS is live so Certbot can request a trusted certificate.
7. Build and start the full stack:

   ```bash
   docker compose up -d --build
   ```

8. Verify the containers are healthy:

   ```bash
   docker compose ps
   docker compose logs -f backend nginx certbot
   ```

9. For a first-time public deployment with `SSL_MODE=letsencrypt`, keep the stack running on ports `80/443`. Certbot will obtain the initial certificate through the shared webroot and then continue checking for renewals every 12 hours. Nginx reloads itself periodically so renewed certificates are picked up without manual intervention.
10. Open `https://example.com` in your browser. API traffic under `/api/` is reverse-proxied to the Express backend, while all other requests are served by the frontend container through the edge Nginx proxy.
11. For upgrades, pull the latest code and redeploy:

   ```bash
   git pull
   docker compose up -d --build
   ```

12. For backups, snapshot the `postgres_data` volume and keep a secure copy of the `certbot_conf` volume if you want to preserve existing certificates across server rebuilds.

## Security Notes

- Secrets are mounted from files instead of being injected directly as environment variables.
- The database lives on an internal-only Docker network so the frontend cannot reach it directly.
- `backend`, `frontend`, `certbot`, and `nginx` use `init: true`, `no-new-privileges`, and reduced writable paths.
- `backend`, `frontend`, `certbot`, and `nginx` run with read-only root filesystems and only the minimum temporary writable directories mounted as `tmpfs`.
