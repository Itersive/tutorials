#!/bin/bash

# Print usage
scriptName=$0
usage() {
  echo -n "Usage:
  ${scriptName} host backup [OPTION]

  Examples:
  ${scriptName} host backup                 restores not encrypted backup on given host
  ${scriptName} host backup -e              restores encrypted archive in given volume and asks for passphrase
  ${scriptName} host backup -ep pass        restores encrypted archive in given volume with given passphrase

  Options:
  -c, --container           Restores backup in Docker container with given host name
  -e, --encrypted           Archive will be decrypted
  -h, --help                Prints this message
  -p, --passphrase string   Passphrase to use during encryption
  -v, --volume string       Name of volume

"
}

OPTIONS=cehp:v:
LONGOPTS=container,encrypted,help,passphrase:,volume:

# -use ! and PIPESTATUS to get exit code with errexit set
# -temporarily store output to be able to check for errors
# -activate quoting/enhanced mode (e.g. by writing out “--options”)
# -pass arguments only via   -- "$@"   to separate them correctly
! PARSED=$(getopt --options=$OPTIONS --longoptions=$LONGOPTS --name "$0" -- "$@")
if [[ ${PIPESTATUS[0]} -ne 0 ]]; then
    # e.g. return value is 1
    #  then getopt has complained about wrong arguments to stdout
    exit 2
fi
eval set -- "$PARSED"

container=n encrypted=n volume=- passphrase=-

while true; do
    case "$1" in
        -c|--container)
            container=y
            shift
            ;;
        -e|--encrypted)
            encrypted=y
            shift
            ;;
        -h|--help)
            usage
            exit 1
            ;;
        -p|--passphrase)
            passphrase="$2"
            shift 2
            ;;
        -v|--volume)
            volume="$2"
            shift 2
            ;;
        --)
            shift
            break
            ;;
        *)
            echo "Error"
            exit 3
            ;;
    esac
done

# handle non-option arguments
if [[ $# -ne 2 ]]; then
    echo "$0: Backup file and host are required."
    exit 4
fi

archive=$1
host=$2
temp_output=temp.tar.gz
backup_dir=backup

mkdir $backup_dir

# handle decryption
if [ $encrypted = "y" ]; then
    if [ $passphrase = "-" ]; then
      openssl enc -d -aes256 -md sha256 -in $archive -out $temp_output
    else
      openssl enc -d -aes256 -md sha256 -in $archive -k $passphrase -out $temp_output
    fi
    mv $temp_output $archive
fi

tar -xzC $backup_dir <$archive

if [ $container = "y" ]; then
    net=temp_backup_network
    docker network create $net &>/dev/null
    docker network connect $net $host
#    docker run --net $net -v $backup_dir:/backup/wekan mongo bash -c 'mongorestore /backup --host '$host':27017'
    docker run --net $net -v /data/config/docker/$backup_dir:/backup mongo bash -c 'mongorestore --host '$host':27017 --db rocketchat --nsInclude '*.bson' /backup/rocketchat'
    docker network disconnect $net $host
    docker network rm $net &>/dev/null
else
    mongorestore $backup_dir --host $host:27017
fi

rm -rf $backup_dir
