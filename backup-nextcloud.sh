#!/usr/bin/env bash

set -eux -o pipefail

: ${DOCKER_VOLUMES_DIR:="/mnt/var/lib/docker/volumes"}
# Change compression if too slow
# see borg help compression
: ${BORG_COMPRESSION:="-C auto,lzma,9"}

# These are the volumes to be backed up
DEFAULT_VOLUMES=(nextcloud_aio_apache
                 nextcloud_aio_nextcloud
                 nextcloud_aio_database
                 nextcloud_aio_database_dump
                 nextcloud_aio_elasticsearch
                 nextcloud_aio_nextcloud_data
                 nextcloud_aio_mastercontainer
                 )


main () {
    sanity_check
    do_backup
    prune_archives
    compact_archives
}

do_backup() {
    backup_ec=0
    borg_command=(borg create -s --list ${BORG_COMPRESSION} "::nexclud-aio-{now:%Y-%m-%dT%H:%M:%S}")
    for volume in "${DEFAULT_VOLUMES[@]}"; do
        borg_command+=("${DOCKER_VOLUMES_DIR}/${volume}")
    done
    time "${borg_command[@]}" || backup_ec=$?
    echo "Backup finished with exit code ${backup_ec}"
    return ${backup_ec}
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
        echo "Or just run 'borg init --encryption=repokey-blake2 "\"${BORG_REPO}\""' in the backup container "\
             "and then rerun the script"
        is_err="1"
    fi

    for volume in "${DEFAULT_VOLUMES[@]}"; do
        if [ ! -e "${DOCKER_VOLUMES_DIR}/${volume}" ] ; then
            echo "${volume} is missing which is not intended."
            exit 1
        fi
    done

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

prune_archives() {
    # Do not quote variable. We need expansion!
    borg prune --stats ${BORG_RETENTION_POLICY}
}
compact_archives() {
    borg compact
}

main "${@}"
