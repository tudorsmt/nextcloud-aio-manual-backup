# Backing up a manual docker install of Nextcloud AIO

This set of scripts is largely based on the [backup model of Nextcloud AIO Docker],
with some lazy simplicity on top.

This assumes you went through the [manual install].

## Important files

`.env` in the one-level-up containing the `BORG_PASSPHRASE` variable

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
