# HOW TO INSTALL WORDPRESS MULTISITE (CLI) — Tailored to This Docker Repo

This guide installs **WordPress Multisite** for the `bandyforbundet` stack entirely from the command line on a Debian 13 guest. It is tailored to the services and scripts in your tarball.

**Repo pieces used**

-   `LOCAL_DOCKER/startup.sh` → orchestrates bring-down/bring-up of stacks and probes Traefik
-   `LOCAL_DOCKER/network_proxy/compose.yaml` → Traefik reverse proxy on :80/:443 with TLS
-   `LOCAL_DOCKER/stacks/compose.yaml` → global stack aggregator
-   `LOCAL_DOCKER/stacks/bandyforbundet/compose.yaml` → WordPress stack (MariaDB, PHP-FPM, Nginx, **bandy-cli**)
-   `LOCAL_DOCKER/stacks/env.wp.sample` → template for site env
-   `LOCAL_DOCKER/stacks/bandyforbundet/.env.wp` → bandyforbundet’s site env
-   `LOCAL_DOCKER/inside.sh` → helper to exec into common services (fpm, **bandy-cli**, nginx, mysql)

---

## 0) Prerequisites — Docker Engine + Compose (Debian 13)

```bash
sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg

# Docker repo
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian $(. /etc/os-release && echo $VERSION_CODENAME) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# (optional) run docker as your user
sudo usermod -aG docker $USER
# log out/in or: newgrp docker
```

---

## 1) Unpack the tarball

```bash
cd /path/where/you/want/
tar xzf LOCAL_DOCKER.tar.gz
cd LOCAL_DOCKER
```

---

## 2) Configure the site environment

Use the sample as a starting point, then edit values to suit your setup.

```bash
cd stacks
cp env.wp.sample bandyforbundet/.env.wp   # overwrite if you want a fresh start
nano bandyforbundet/.env.wp
```

**Typical `.env.wp`**

```ini
# Database (unique per site)
WP_DB_NAME=wordpress_bandy
WP_DB_USER=wp_bandy
WP_DB_PASSWORD=changeMeBandy123

# Public host (Traefik + WP URLs)
WP_DOMAIN=bandyforbundet.localhost

# WordPress admin used by CLI install
WP_ADMIN_USER=admin
WP_ADMIN_PASSWORD=ChangeMe123!
WP_ADMIN_EMAIL=you@example.com
```

> The `bandyforbundet/compose.yaml` reads these via `${...}`. The DB host is provided by Docker networking as `bandy-mysql:3306`.

---

## 3) Bring the stack up (recommended: use `startup.sh`)

`startup.sh` centralizes the workflow (ensures `web` network, restarts the proxy and stacks, and probes routes through Traefik).

```bash
cd ~/.../LOCAL_DOCKER
./startup.sh
```

**What it does behind the scenes**

-   Creates/ensures the external Docker network `web`
-   Starts Traefik from `network_proxy/compose.yaml`
-   Starts global stacks from `stacks/compose.yaml`
-   Starts the bandy stack from `stacks/bandyforbundet/compose.yaml`
-   Probes domains (defaults include `bandyforbundet.localhost`)

**Manual alternative**

```bash
docker network create web || true
(cd network_proxy && docker compose up -d)
(cd stacks && docker compose -f compose.yaml up -d)
(cd stacks/bandyforbundet && env $(grep -v '^#' .env.wp | xargs) docker compose up -d)
```

Give MariaDB ~15–30s to initialize on first run.

fix:

tar cvzf LOCAL_DOCKER.tar.gz --exclude=".git" LOCAL_DOCKER/
