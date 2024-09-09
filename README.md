# Backing up a manual docker install of Nextcloud AIO

This set of scripts is largely based on the [backup model of Nextcloud AIO Docker],
with some lazy simplicity on top.

This assumes you went through the [manual install].

The backup model here will back up the entire docker volumes used by the nextcloud AIO
installation, without any regard for minimum-data-backup practices. Space is cheap
enough, for now, restoring is much faster.

## Important files

`.env` in the one-level-up containing the `BORG_PASSPHRASE` variable. It is assumed
that the repository is cloned in the same directory where the `docker-compose.yaml` and
`.env` used by this file are present:

```
$ tree -L 2 .
.
├── docker-compose.yaml
└── nextcloud-aio-manual-backup
    ├── backup-nextcloud.sh
    ├── Dockerfile
    ├── README.md
    ├── run-backup.sh
    └── storage

```

`run-backup.sh` is the main script to use. This will auto-run the backup of
nextcloud volumes. Any other parameters will drop you to the container
shell, giving you the chance to use borg manually. This is the only way
to restore a backup.

`backup-nextcloud.sh` is the internal backup execution script, ran in the container,
that backs up all the `nextcloud_aio_*` docker volumes found on the host, in the
standard location.

The scripts should be simple enough to not cause too much confusion.

## Where is my backup?

In the directory `storage`

[manual install]: https://github.com/nextcloud/all-in-one/tree/main/manual-install
[backup model of Nextcloud AIO Docker]: https://github.com/nextcloud/all-in-one/tree/main/Containers/borgbackup

*_YOU_* Are responsible to keep the backup safe. Use any storage that you want: NAS, USB Stick,
pushing to other Borg remotes.

## How to restore?

1. Make sure all the needed volumes exist. Easiest way is to wipe the installation and run from scratch.
   Be careful not to delete the backup, in the process :)
2. Make sure all the Nextcloud AIO containers are stopped.
3. run the backup contaioner
4. do a `borg list` and pick a backup. Do some creative exploration in case the latest is not good enough.
5. `borg extract $BORG_REPO::<THE-BACKUP-TAG-YOU-WANT>` and wait
6. Start the Nextcloud AIO Containers
