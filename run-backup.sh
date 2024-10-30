#!/usr/bin/env bash
set -eu -o pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Load the general settings, like the BORG_PASSPHRASE
source "$(realpath "${SCRIPT_DIR}/../.env")"

BACKUP_STORAGE="${SCRIPT_DIR}/storage"
DOCKER_LIB_DIR="/var/lib/docker"
BORG_REPO="/mnt/backup/storage"

BACKUP_IMAGE="nextcloud-aio-manual-backup"
docker_run=(docker run --rm)
docker_params=(-v ${DOCKER_LIB_DIR}:/mnt/var/lib/docker
               -v "${BACKUP_STORAGE}:${BORG_REPO}"
               -e BORG_PASSPHRASE="${BORG_PASSPHRASE}"
               -e BORG_REPO="${BORG_REPO}"
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
            ${docker_run[@]} -it ${docker_params[@]}
            ;;
        *)
            mkdir -p "${BACKUP_STORAGE}"
            echo "Running the backup script"
            backup_ec=0
            ${docker_run[@]} ${docker_params[@]} /backup-nextcloud.sh || backup_ec=$?
            # Change ownership of the backup to the current user, regardless
            # of what happened during the backup.
            ${docker_run[@]} ${docker_params[@]} chown -R "$(id -u):$(id -g)" "${BORG_REPO}"
            exit $backup_ec
            ;;
    esac
}

_enable_maintenance_mode() {
    echo "Enabling NextCloud Maintenance mode, so no unexpected changes happen"
    docker compose exec nextcloud-aio-nextcloud sudo -u www-data PHP_MEMORY_LIMIT=512M php occ maintenance:mode --on
}
_disable_maintenance_mode() {
    echo "Disabling NextCloud Maintenance mode - ready to work"
    docker compose exec nextcloud-aio-nextcloud sudo -u www-data PHP_MEMORY_LIMIT=512M php occ maintenance:mode --off
}

_maybe_build_backup_image() {
    if ! docker image ls -q "${BACKUP_IMAGE}" | grep -q "." ; then
        echo "Docker image "${BACKUP_IMAGE}" needed for backing up not found on host, building"
        pushd "${SCRIPT_DIR}"
        # Use plain output, not fancy colorful one
        BUILDKIT_PROGRESS=plain docker build -t "${BACKUP_IMAGE}" .
        popd
    else
        echo "Docker image "${BACKUP_IMAGE}" found on host, no need to build, will directly run"
    fi
}

main "${@}"
