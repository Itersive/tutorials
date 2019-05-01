#!/bin/bash

hostPath=$1
bckContRunningFlag=0
net=temp_backup_network

runContBackup(){
    vendor=$(echo $1 | tr '[A-Z]' '[a-z]')
    host=$(echo $2 | awk -F '[:]' '{print $1}')
    if [ $(echo $2 | awk -F '[:]' '{print $2}') ]; then
        port=$(echo $2 | awk -F '[:]' '{print $2}')
    else
        if [[ $vendor = 'postgres' ]]; then
            port=5432
        elif
            [[ $vendor = 'mongodb' ]];then
            port=27017
        fi
    fi
    #echo -e "\n\n$host $port $vendor\n\n"


    echo -e "attaching backupcontainer newtork to $host"
    docker network connect $net $host &>/dev/null

    case $vendor in
        postgres)
            currTimeDate=$(date +%Y%m%d%H%M%S)
            echo -e "Starting postgres backup for $host"
            docker exec backupcontainer bash -c 'pg_basebackup -F t -z -h '$host' -p '$port' -U backupuser -w -X stream -D /backup/dbbackup/'$host'_'$currTimeDate'; tar -cvzf /backup/dbbackup/'$host'_'$currTimeDate'.tar.gz -C /backup/dbbackup '$host'_'$currTimeDate'; rm -rf /backup/dbbackup/'$host'_'$currTimeDate''
            ;;
        mongodb)
            currTimeDate=$(date +%Y%m%d%H%M%S)
            echo -e "Starting mongodb backup for $host"
	    docker exec backupcontainer bash -c 'mongodump --gzip --archive=/backup/dbbackup/'$host'_'$currTimeDate'.gz --host='$host' --port='$port''
            ;;
    esac

    echo "Removing files older than 7 days"
    docker exec backupcontainer bash -c 'find /backup/* -mtime +7 -exec rm {} \;'
    # change permissions to docker:itersive on backup directory and contents
    docker exec backupcontainer bash -c 'chown -R 4001:3000 /backup'
    docker network disconnect $net $host &>/dev/null
}

runContainer(){
    if [[ bckContRunningFlag -eq 0 ]]; then
        docker network create $net &>/dev/null
        docker run -itd --net $net --rm -v /data/backup:/backup --name backupcontainer --userns=host backupcontainer &>/dev/null

        #checking if container started (3 times, 5 sec sleep)
        for i in 1 2 3; do
            if [ $(docker ps --format {{.Names}} | grep -i backupcontainer) ]; then
                echo -e "Backup Container started, launching backup for $1 $2\n"
                bckContRunningFlag=1
                runContBackup "$1" "$2"
                break
            else
                echo -e "Container didn't start, sleeping for 5 seconds...\n"
                sleep 5
            fi
        done
    else
        echo -e "Backup container is already up and running, launching backup for $1 $2\n"
        runContBackup "$1" "$2"
    fi
}

stopContainer(){
    if [[ bckContRunningFlag -eq 1 ]]; then
        echo -e "Stopping backup container..."
        docker rm -f backupcontainer
    fi
}
if [[ -z ${hostPath} ]]; then
    echo "Please provide path to hostlist after ${0}
    eg. ${0} /path/to/hostlist/file/
    "
    exit 1
fi

while IFS='= :' read cont key value; do
    counthosts=$(echo "$value" | tr -d ' ' | tr ',' '\n' | wc -l)
    i=1
    echo -e "\ncurrent line = $cont : $key : $value"
    while [ $i -le ${counthosts} ]; do
        singlehost=$( echo "$value" | tr -d ' ' | cut -d, -f$i )
        echo -e "beginning backup of: $key $singlehost"
        case $cont in
            cont*)
                runContainer "$key" "$singlehost"
                ;;
            *)
                echo -e "running non container backup for $key $singlehost"
                ;;
            esac
        i=$(($i+1))
    done
done < ${hostPath}/hostlist

stopContainer
