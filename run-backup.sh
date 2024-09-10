#!/usr/bin/env bash
set -eu -o pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Load the general settings, like the BORG_PASSPHRASE
source "$(realpath "${SCRIPT_DIR}/../.env")"

BACKUP_STORAGE="${SCRIPT_DIR}/storage"
DOCKER_LIB_DIR="/var/lib/docker"


BACKUP_IMAGE="nextcloud-aio-manual-backup"
docker_cmd=(docker run -it --rm \
            -v ${DOCKER_LIB_DIR}:/mnt/var/lib/docker
            -v "${BACKUP_STORAGE}:/mnt/backup/storage"
            -e BORG_PASSPHRASE="${BORG_PASSPHRASE}"
            -e BORG_REPO=/mnt/backup/storage
            "${BACKUP_IMAGE}"
            )

main() {
    trap _disable_maintenance_mode EXIT
    _maybe_build_backup_image
    _enable_maintenance_mode
    case "${1-}" in
        help|-h|--help)
            echo "Use 'container' to drop into a shell in the backup container. Any other parameter will "\
                 "trigger the backup execution"
            ;;
        container)
            ${docker_cmd[@]}
            ;;
        *)
            mkdir -p "${BACKUP_STORAGE}"
            echo "Running the backup script"
            ${docker_cmd[@]} /backup-nextcloud.sh
            ;;
    esac
}

_enable_maintenance_mode() {
    echo "Enabling NextCloud Maintenance mode, so no unexpected changes happen"
    docker compose exec nextcloud-aio-nextcloud sudo -u www-data php occ maintenance:mode --on
}
_disable_maintenance_mode() {
    echo "Disabling NextCloud Maintenance mode - ready to work"
    docker compose exec nextcloud-aio-nextcloud sudo -u www-data php occ maintenance:mode --off
}

_maybe_build_backup_image() {
    if ! docker image ls -q "${BACKUP_IMAGE}" | grep -q "." ; then
        echo "Docker image "${BACKUP_IMAGE}" needed for backing up not found on host, building"
        pushd "${SCRIPT_DIR}"
        docker build -t "${BACKUP_IMAGE}" .
        popd
    else
        echo "Docker image "${BACKUP_IMAGE}" found on host, no need to build, will directly run"
    fi
}

main "${@}"
