#!/bin/bash

# Print usage
scriptName="restore.sh"
usage() {
  echo -n "Usage:
  ${scriptName} archive -v volume [OPTION]

  Examples:
  ${scriptName} archive -v volume           restores not encrypted archive in given volume
  ${scriptName} archive -o volume -e        restores encrypted archive in given volume and asks for passphrase
  ${scriptName} archive -o volume -ep pass  restores encrypted archive in given volume with given passphrase

  Options:
  -e, --encrypted           Archive will be decrypted
  -h, --help                Prints this message
  -p, --passphrase string   Passphrase to use during encryption
  -v, --volume string       Name of volume

"
}

OPTIONS=ehp:v:
LONGOPTS=encrypted,help,passphrase:,volume:

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

encrypted=n volume=- passphrase=-

while true; do
    case "$1" in
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
if [[ $# -ne 1 ]]; then
    echo "$0: A single file is required."
    exit 4
fi

archive=$1
archive_decrypted=decrypted.tar.gz

echo "archive: $archive_decrypted, encrypt: $encrypted, volume: $volume"

# handle decryption
if [ $encrypted = "y" ]; then
    if [ $passphrase = "-" ]; then
      openssl enc -d -aes256 -md sha256 -in $archive -out $archive_decrypted
    else
      openssl enc -d -aes256 -md sha256 -in $archive -k $passphrase -out $archive_decrypted
    fi
    mv $archive_decrypted $archive
fi

docker run --rm -i -v $volume:/target busybox tar -xzC /target <$archive
