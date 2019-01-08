# Backup Docker volumes

Simple bash scripts for creating encrypted backups of Docker volumes and restoring them.


# Prerequisites

* Docker
* Openssl
* Terminal

# Usage

* Create backup of Docker volume:

```
backup.sh volume [OPTION]

Examples:
backup.sh volume                            creates not encrypted archive with backup_date.tar.gz name from given volume
backup.sh volume -o volume_backup           creates not encrypted volume_backup.tar.gz archive from given volume
backup.sh volume -o volume_backup -e        creates encrypted volume_backup.tar.gz archive from given volume and asks for passphrase
backup.sh volume -o volume_backup -eg       creates encrypted volume_backup.tar.gz archive from given volume with generated passphrase
backup.sh volume -o volume_backup -ep pass  creates encrypted volume_backup.tar.gz archive from given volume with given passphrase

```

* Restore data from backup in Docker volume:

```
restore.sh archive -v volume [OPTION]

Examples:
restore.sh archive -v volume           restores not encrypted archive in given volume
restore.sh archive -o volume -e        restores encrypted archive in given volume and asks for passphrase
restore.sh archive -o volume -ep pass  restores encrypted archive in given volume with given passphrase

```

* Use `-h` or `--help` option to see full message.

# Summary

Two simple bash scripts for Linux environment (at least tested in Linux env) for backup/restore Docker volumes.

See scripts in this directory for details.

# Sources

* [Backup/restore with utility container](https://stackoverflow.com/questions/53621829/backup-and-restore-docker-named-volume)
* [Bash options](https://stackoverflow.com/questions/192249/how-do-i-parse-command-line-arguments-in-bash)
* [Random generator](https://gist.github.com/earthgecko/3089509)
