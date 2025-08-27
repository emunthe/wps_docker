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
