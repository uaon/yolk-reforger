#!/bin/bash

# Copy from github.com/parkervcp/images
# Modifed by: Josh Edson (Sweetwater.I)

armaGameID=1874900
# Color Codes
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

cd /home/container
sleep 1


export STEAM_USER=${STEAM_USER}
export STEAM_PASS=${STEAM_PASS}
export LD_PRELOAD=/libnss_wrapper_x64.so

# Set environment variable that holds the Internal Docker IP
INTERNAL_IP=$(ip route get 1 | awk '{print $(NF-2);exit}')
export INTERNAL_IP

# Update dedicated server, if specified
if [[ ${UPDATE_SERVER} == "1" ]];
then
	echo -e "\n${GREEN}STARTUP:${NC} Checking for updates to game server with App ID: ${CYAN}${STEAMCMD_APPID}${NC}...\n"
	if [[ -f ./steam.txt ]];
	then
		echo -e "\n${GREEN}STARTUP:${NC} steam.txt found in root folder. Using to run SteamCMD script...\n"
		./steamcmd/steamcmd.sh +login ${STEAM_USER} ${STEAM_PASS} +force_install_dir /home/container +app_update ${STEAMCMD_APPID} ${STEAMCMD_EXTRA_FLAGS} validate +runscript /home/container/steam.txt
	else
		./steamcmd/steamcmd.sh +login ${STEAM_USER} ${STEAM_PASS} +force_install_dir /home/container +app_update ${STEAMCMD_APPID} ${STEAMCMD_EXTRA_FLAGS} validate +quit
	fi
	echo -e "\n${GREEN}STARTUP: Game server update check complete!${NC}\n"
fi

if [[ ! -f ./${SERVER_BINARY} ]];
then
	echo -e "\n${RED}STARTUP_ERR: Specified server binary could not be found in files!${NC}"
	exit 1
fi

export USER_ID=$(id -u)
export GROUP_ID=$(id -g)
envsubst < /passwd.template > ${NSS_WRAPPER_PASSWD}

MODIFIED_STARTUP=`eval echo $(echo ${STARTUP} | sed -e 's/{{/${/g' -e 's/}}/}/g')`

chmod +x ArmaReforgerServer

# Start the Server
echo -e "\n${GREEN}STARTUP:${NC} Starting server with the following startup command:"
echo -e "${CYAN}${MODIFIED_STARTUP}${NC}\n"
${MODIFIED_STARTUP} 2>&1 | tee ${LOG_FILE}

if [ $? -ne 0 ];
then
	echo -e "\n${RED}PTDL_CONTAINER_ERR: There was an error while attempting to run the start command.${NC}\n"
	exit 1
fi