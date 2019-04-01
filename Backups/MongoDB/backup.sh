#!/bin/bash

# Print usage
scriptName=$0
usage() {
  echo -n "Usage:
  ${scriptName} host [OPTION]

  Examples:
  ${scriptName} host                        creates not encrypted archive with backup_date.tar.gz name from given host
  ${scriptName} host -o backup              creates not encrypted backup.tar.gz archive from given host
  ${scriptName} host -o backup -e           creates encrypted backup.tar.gz archive from given host and asks for passphrase
  ${scriptName} host -o backup -eg          creates encrypted backup.tar.gz archive from given host with generated passphrase
  ${scriptName} host -o backup -ep pass     creates encrypted backup.tar.gz archive from given host with given passphrase
  ${scriptName} host -o backup -c           creates not encrypted backup.tar.gz archive from given 'host' container

  Options:
  -c, --container           Create backup from Docker container with given host name
  -e, --encrypt             Archive will be encrypted
  -g, --generate            Passphrase will be generated and printed at the end
  -h, --help                Prints this message
  -p, --passphrase string   Passphrase to use during encryption
  -o, --output string       Name of archive. Otherwise name will be backup_date.tar.gz

"
}

OPTIONS=ceghp:o:
LONGOPTS=container,encrypt,generate,help,passphrase:,output:

! PARSED=$(getopt --options=$OPTIONS --longoptions=$LONGOPTS --name "$0" -- "$@")
if [[ ${PIPESTATUS[0]} -ne 0 ]]; then
    exit 2
fi
eval set -- "$PARSED"

container=n encrypt=n generate=n output=backup_$(date +%Y%m%d).tar.gz passphrase=-

while true; do
    case "$1" in
        -c|--container)
            container=y
            shift
            ;;
        -e|--encrypt)
            encrypt=y
            shift
            ;;
        -g|--generate)
            generate=y
            # generate random 32 character alphanumeric string
            passphrase=$(cat /dev/urandom \
              | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
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
        -o|--output)
            output="$2.tar.gz"
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
if [[ $# -ne 1 ]]; then
    echo "$0: A host is required."
    exit 4
fi

host=$1
temp_output=temp.tar.gz
backup_dir=/home/docker/backup

mkdir $backup_dir

if [ $container = "y" ]; then
    net=temp_backup_network
    docker network create $net &>/dev/null
    docker network connect $net $host
    docker run --net $net -v $backup_dir:/backup --userns=host mongo bash -c 'mongodump --out /backup --host '$host':27017;' #&>/dev/null --userns=host
    docker network disconnect $net $host
    docker network rm $net &>/dev/null
else
    mongodump --out $backup_dir --host $host:27017
fi

tar -czC $backup_dir . >$temp_output

# handle encryption
if [ $encrypt = "y" ]; then
    if [ $passphrase = "-" ]; then
      openssl enc -e -aes256 -md sha256 -in $temp_output -out $output
    else
      openssl enc -e -aes256 -md sha256 -in $temp_output -k $passphrase -out $output
      if [ $generate = "y" ]; then
        echo "Archive encrypted with:" $passphrase
      fi
    fi
    rm $temp_output
else
    mv $temp_output $output
fi

rm -rf $backup_dir
