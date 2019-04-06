#!/bin/bash

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
            echo -e "Starting postgres backup for $host"
            ;;
        mongodb)
            echo -e "Starting mongodb backup for $host"
            ;;
    esac
    docker network disconnect $net $host &>/dev/null
}

runContainer(){
    if [[ bckContRunningFlag -eq 0 ]]; then
        docker network create $net &>/dev/null
        docker run -itd --net $net --rm -v /tmp:/backup --name backupcontainer --userns=host backupcontainer &>/dev/null

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
                echo -e "running non container bakcup for $key $singlehost"
                ;;
            esac
        i=$(($i+1))
    done
done < hostlist

stopContainer
