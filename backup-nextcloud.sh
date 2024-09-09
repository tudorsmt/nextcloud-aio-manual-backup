#!/usr/bin/env bash

set -eu -o pipefail

DOCKER_VOLUMES_DIR=/mnt/var/lib/docker/volumes
# Change compression if too slow
# see borg help compression
BORG_COMPRESSION="-C auto,lzma,9"

main () {
    sanity_check
    do_backup
}

do_backup() {
    time borg create -s --list ${BORG_COMPRESSION} "::nexclud-aio-{now:%Y-%m-%dT%H:%M:%S}" \
        /mnt/var/lib/docker/volumes/nextcloud_aio_*
}

sanity_check () {
    if [ -z "${BORG_PASSPHRASE-}" ]; then
        echo "Please set the environment variable BORG_PASSPHRASE"
        # Content does not matter, as will test against empty or not.
        is_err="1"
    fi
    if [ -z "${BORG_REPO-}" ]; then
        echo "Please set the environment variable BORG_PASSPHRASE"
        # Content does not matter, as will test against empty or not.
        is_err="1"
    fi
    if ! list_repo_info; then
        echo "Ensure that a valid borg repository is created at ${BORG_REPO}. See 'borg init'"
        echo "Or just run 'borg init --encryption=repokey "\"${BORG_REPO}\""' in the backup container "\
             "and then rerun the script"
        is_err="1"
    fi

    if [ "$(find "${DOCKER_VOLUMES_DIR}" -mindepth 1 -maxdepth 1 -name "nextcloud_aio_*" | wc -l)" -lt 8 ]; then
        echo "Expecting at least 8 nextcloud volumes, found: "
        find "${DOCKER_VOLUMES_DIR}" -mindepth 1 -maxdepth 1 -name "nextcloud_aio_*"
        is_err="1"
    fi

    # -u flag here doesn't kick in, as we have default of empty.
    if [ -n "${is_err-}" ]; then
        exit 1
    fi
}

list_repo_info () {
    echo "Checking validity of the borg repo ${BORG_REPO}"
    borg info
}

main "${@}"
