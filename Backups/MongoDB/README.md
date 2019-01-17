# Backup MongoDB

Simple bash scripts for creating encrypted backups of MongoDB and restoring them.


# Prerequisites

* Openssl
* Terminal
* Docker - optional

# Usage

* Create backup:

```
./backup.sh host [OPTION]

Examples:
./backup.sh host                        creates not encrypted archive with backup_date.tar.gz name from given host
./backup.sh host -o backup              creates not encrypted backup.tar.gz archive from given host
./backup.sh host -o backup -e           creates encrypted backup.tar.gz archive from given host and asks for passphrase
./backup.sh host -o backup -eg          creates encrypted backup.tar.gz archive from given host with generated passphrase
./backup.sh host -o backup -ep pass     creates encrypted backup.tar.gz archive from given host with given passphrase
./backup.sh host -o backup -c           creates not encrypted backup.tar.gz archive from given 'host' container
```

* Restore data from backup in Docker volume:

```
./restore.sh host backup [OPTION]

Examples:
./restore.sh host backup                 restores not encrypted backup on given host
./restore.sh host backup -e              restores encrypted archive in given volume and asks for passphrase
./restore.sh host backup -ep pass        restores encrypted archive in given volume with given passphrase
```

* Use `-h` or `--help` option to see full message.

# Commands

Instead of scripts you can use those commands for simple backup and restore:

```
mongodump --out $backup_dir --host $host:27017
```

and

```
mongorestore $backup_dir --host $host:27017
```

If MongoDB is deployed on Docker:

```
docker network create $net
docker network connect $net $host
docker run --net $net -v $backup_dir:/backup mongo bash -c 'mongodump --out /backup --host '$host':27017'
docker network disconnect $net $host
docker network rm $net
```

and

```
docker network create $net
docker network connect $net $host
docker run --net $net -v $backup_dir:/backup mongo bash -c 'mongorestore /backup --host '$host':27017'
docker network disconnect $net $host
docker network rm $net
```

where `$host` is IP address or Docker container name, `$backup_dir` is directory where backup is stored
and `$net` is the name of temporary network.


# Summary

Two simple bash scripts for Linux environment (at least tested in Linux env) for backup/restore MongoDB.

See scripts in this directory for details.

# Sources

* [Bash options](https://stackoverflow.com/questions/192249/how-do-i-parse-command-line-arguments-in-bash)
* [Random generator](https://gist.github.com/earthgecko/3089509)
