# Updated: Single Shared Traefik for Multiple Sites

This update removes the per-project Traefik in `all_docker_servers/compose.yaml` and relies on the shared proxy in `all_docker_network_proxy/compose.yaml`.

## How to use

1. From `local_docker/all_docker_network_proxy/`:

    ```bash
    docker compose up -d
    ```

    - Publishes 80/443 and dashboard on 127.0.0.1:8081
    - Uses the external Docker network `web`
    - Loads middleware and default TLS from `./dynamic/dynamic.toml`

2. From `local_docker/all_docker_servers/`:

    ```bash
    docker compose up -d
    ```

    - Sites register via labels to the shared Traefik.
    - No app service publishes web ports.

## Access

-   https://bandyforbundet.localhost
-   https://espenmunthe.localhost
-   Traefik dashboard: http://127.0.0.1:8081

> Make sure your certs exist in `all_docker_network_proxy/certs/`:
>
> -   `wildcard-localhost.pem`
> -   `wildcard-localhost-key.pem`

#

# make wp-cli search replace command for https://bandyforbundet.no to https://bandyforbundet.localhost

wp search-replace 'https://bandyforbundet.no' 'https://bandyforbundet.localhost' --url='https://bandyforbundet.no' --all-tables --dry-run

wp search-replace 'bandyforbundet.no' 'bandyforbundet.localhost' --url='https://bandyforbundet.no' --all-tables --dry-run


## Method A — Localhost Development (Debian VM or local Docker)

This method keeps production config intact and layers **dev-only overrides** that:
- run Traefik on **HTTP only** (no ACME),
- register dev hostnames under a dynamic domain like `<VM-IP>.nip.io`,
- point routes to your local containers.

### Quick start

```bash
cd wps_docker
./dev_up.sh
# Script will auto-detect your VM IP and set DEV_DOMAIN=<ip>.nip.io

# Static site:
#   http://espenmunthe.<ip>.nip.io
# WordPress (bandy):
#   http://bandy.<ip>.nip.io
# Traefik dashboard:
#   http://<ip>:8080/dashboard
```

To stop the dev stack:
```bash
./dev_down.sh
```

### Files added for dev

- `network_proxy/compose.override.dev.yaml` — Traefik HTTP entrypoint + dashboard
- `stacks/compose.override.dev.yaml` — dev router for `espenmunthe`
- `stacks/bandyforbundet/compose.override.dev.yaml` — dev router for `bandy`
- `dev_up.sh`, `dev_down.sh` — helpers to bring stacks up/down with overrides
- `stacks/bandyforbundet/html/index.php` — tiny PHP page to smoke‑test nginx → php‑fpm

### Notes

- No `/etc/hosts` edits are required; `nip.io` resolves any `<ip>.nip.io` hostname to the IP.
- For HTTPS locally, consider `mkcert` and a Traefik TLS file provider (not necessary for dev HTTP).
- These overrides are **dev-only** and won’t affect production unless you include them with `-f ...override.dev.yaml`.
