#!/bin/bash

# Print usage
scriptName="backup.sh"
usage() {
  echo -n "Usage:
  ${scriptName} volume [OPTION]

  Examples:
  ${scriptName} volume                            creates not encrypted archive with backup_date.tar.gz name from given volume
  ${scriptName} volume -o volume_backup           creates not encrypted volume_backup.tar.gz archive from given volume
  ${scriptName} volume -o volume_backup -e        creates encrypted volume_backup.tar.gz archive from given volume and asks for passphrase
  ${scriptName} volume -o volume_backup -eg       creates encrypted volume_backup.tar.gz archive from given volume with generated passphrase
  ${scriptName} volume -o volume_backup -ep pass  creates encrypted volume_backup.tar.gz archive from given volume with given passphrase

  Options:
  -e, --encrypt             Archive will be encrypted
  -g, --generate            Passphrase will be generated and printed at the end
  -h, --help                Prints this message
  -p, --passphrase string   Passphrase to use during encryption
  -o, --output string       Name of archive. Otherwise name will be backup_date.tar.gz

"
}

OPTIONS=eghp:o:
LONGOPTS=encrypt,generate,help,passphrase:,output:

! PARSED=$(getopt --options=$OPTIONS --longoptions=$LONGOPTS --name "$0" -- "$@")
if [[ ${PIPESTATUS[0]} -ne 0 ]]; then
    exit 2
fi
eval set -- "$PARSED"

encrypt=n generate=n output=backup_$(date +%Y%m%d).tar.gz passphrase=-

while true; do
    case "$1" in
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
    echo "$0: A single volume is required."
    exit 4
fi

volume=$1
output_encrypted=encrypted.tar.gz
echo "volume: $volume, encrypt: $encrypt, out: $output"

docker run --rm -v $volume:/source:ro busybox tar -czC /source . >$output_encrypted

# handle encryption
if [ $encrypt = "y" ]; then
    if [ $passphrase = "-" ]; then
      openssl enc -e -aes256 -md sha256 -in $output_encrypted -out $output
    else
      openssl enc -e -aes256 -md sha256 -in $output_encrypted -k $passphrase -out $output
      if [ $generate = "y" ]; then
        echo "Archive encrypted with:" $passphrase
      fi
    fi
    rm $output_encrypted
fi
