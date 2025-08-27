# CHECK_SETUP

## What's in the tarball (key bits)

    LOCAL_DOCKER/
      startup.sh                      # orchestrates the whole bring-up
      .env                            # project env (if used)
      network_proxy/
        compose.yaml                  # Traefik reverse proxy (ports 80/443 + dashboard)
        .env
        certs/
          wildcard-localhost.pem
          wildcard-localhost-key.pem  # TLS for *.localhost
        dynamic/dynamic.toml          # default TLS + optional dashboard router
      stacks/
        compose.yaml                  # “global” stack (e.g., espenmunthe static site, autonomi)
        .env
        espenmunthe/public/index.html # static site content
        autonomi/{Dockerfile,.env,entrypoint.sh}
        bandyforbundet/
          compose.yaml                # WordPress + MariaDB stack
          .env.wp                     # WP/MariaDB credentials & domain
        traefik/
          dynamic.toml                # (legacy/per-stack) TLS config

## Start it up

Prereqs: Docker Engine + Docker Compose v2, ports 80/443 free.

```bash
cd LOCAL_DOCKER
# one-time, if needed
docker network create web 2>/dev/null || true
chmod +x startup.sh
./startup.sh
```

### 1) Containers and network

```bash
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
docker network ls | grep -w web
```

✅ Already shows `web` bridge network exists.

### 2) Check Traefik and HTTPS

```bash
curl -I http://127.0.0.1:8081     # Traefik dashboard
curl -I http://localhost          # Port 80
curl -kI https://localhost        # Port 443 with TLS
```

### 3) Routes via \*.localhost

Try these (note: WordPress may fail because `bandy-nginx` is
restarting):

```bash
curl -kI https://espenmunthe.localhost
curl -kI https://bandyforbundet.localhost
```

tar -czf WPS_DOCKER.tar.gz --exclude=".git" WPS_DOCKER/
