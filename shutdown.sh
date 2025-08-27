#!/usr/bin/env bash
set -Eeuo pipefail

KEEP_VOLUMES="${KEEP_VOLUMES:-0}"   # 1 = keep volumes, 0 = remove
REMOVE_ORPHANS="${REMOVE_ORPHANS:-1}"

echo ">> Discovering Docker Compose projects from running containers..."

# Collect unique container IDs that have compose labels
mapfile -t containers < <(docker ps -q)

declare -A PROJECTS_WD
declare -A PROJECTS_CFGS

for id in "${containers[@]}"; do
  proj=$(docker inspect -f '{{ index .Config.Labels "com.docker.compose.project" }}' "$id" 2>/dev/null || true)
  [[ -n "${proj:-}" ]] || continue
  wd=$(docker inspect -f '{{ index .Config.Labels "com.docker.compose.project.working_dir" }}' "$id" 2>/dev/null || true)
  cfgs=$(docker inspect -f '{{ index .Config.Labels "com.docker.compose.project.config_files" }}' "$id" 2>/dev/null || true)

  # Some engines may not set working_dir/config_files; skip if we can't reconstruct
  [[ -n "${wd:-}" && -n "${cfgs:-}" ]] || continue

  PROJECTS_WD["$proj"]="$wd"
  PROJECTS_CFGS["$proj"]="$cfgs"
done

if [[ "${#PROJECTS_WD[@]}" -eq 0 ]]; then
  echo ">> No compose-labelled projects found from running containers."
else
  echo ">> Bringing down compose projects:"
  for proj in "${!PROJECTS_WD[@]}"; do
    wd="${PROJECTS_WD[$proj]}"
    cfgs_raw="${PROJECTS_CFGS[$proj]}"
    echo "   - $proj (wd: $wd, cfgs: $cfgs_raw)"

    # Normalize config files into repeated -f flags (handle :,;, and , separators)
    compose_files_args=()
    IFS=':;,' read -r -a cfg_array <<< "$cfgs_raw"
    for f in "${cfg_array[@]}"; do
      [[ -z "$f" ]] && continue
      compose_files_args+=( -f "$wd/$f" )
    done
    unset IFS

    # Build the down command
    cmd=( docker compose -p "$proj" "${compose_files_args[@]}" down )
    [[ "$KEEP_VOLUMES" == "0" ]] && cmd+=( -v )
    [[ "$REMOVE_ORPHANS" == "1" ]] && cmd+=( --remove-orphans )

    # Execute (don’t fail the whole script if one project errors)
    echo ">> ${cmd[*]}"
    "${cmd[@]}" || true
  done
fi

echo ">> Disabling restart policy on any remaining containers to prevent respawn..."
if docker ps -q | grep -q .; then
  docker update --restart=no $(docker ps -q) || true
fi

echo ">> Stopping and removing any leftover containers (non-compose or missed ones)..."
if docker ps -q | grep -q .; then
  docker stop $(docker ps -q) || true
fi
if docker ps -aq | grep -q .; then
  docker rm -f $(docker ps -aq) || true
fi

if [[ "$KEEP_VOLUMES" == "0" ]]; then
  echo ">> Pruning dangling/unused volumes..."
  docker volume prune -f || true
fi

echo ">> Pruning unused networks..."
docker network prune -f || true

echo ">> Done."
