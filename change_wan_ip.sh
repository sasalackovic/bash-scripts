#!/bin/bash

# Bash script that detects if a public IP address of a home server changed. If it has changed, then update the file with a new IP address. After that it restarts the node run in a docker container called 'shardeum-dashboard'

# Function to get the current date and time in the format "dd.mm.yyyy hh:mm"
timestamp() {
     date +"%d.%m.%Y %H:%M:%S"
}

echo "$(timestamp) - Checking WAN IP address..."

ENV_FILE='/root/.shardeum/.env'
IP_FILE='/root/.shardeum/ip_checker/current_ip'

old_ip=`cat $IP_FILE`
new_ip=`wget -q -O - ipinfo.io/ip`

if [ "$old_ip" != "$new_ip" ]; then
        echo "$(timestamp) - Old IP address: $old_ip"
        echo "$(timestamp) - New IP address: $new_ip"
        sed -i "s/SERVERIP=$old_ip/SERVERIP=$new_ip/g" "$ENV_FILE"
        sed -i "s/$old_ip/$new_ip/g" "$IP_FILE"

        echo "$(timestamp) - Succesfully changed IP address in $ENV_FILE. Restarting Shardeum node..."

        # Check if the Docker container 'shardeum-dashboard' is running
        if [ $(docker ps -q -f name=shardeum-dashboard) ]; then
                docker exec -it shardeum-dashboard operator-cli stop
                /root/.shardeum/update.sh
                docker exec -it shardeum-dashboard operator-cli start
                echo "$(timestamp) - Shardeum node restarted."
        else
                echo "$(timestamp) - Docker container 'shardeum-dashboard' is not running. Please start the container first."
        fi

        printf "\n\n"

        exit 1
fi

printf "$(timestamp) - IP address is the same ($old_ip = $new_ip). Not changing!\n\n"
