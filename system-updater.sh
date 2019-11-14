#!/bin/bash

# color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;35m'
ORANGE='\033[1;33m'
NC='\033[0m' # No Color

name="system-updater"
version="v0.1"

LATEST_INFO_URL="https://raw.githubusercontent.com/ODEX-TOS/system-updater/master/tos-latest.info"
PACKAGES="https://raw.githubusercontent.com/ODEX-TOS/system-updater/master/packages"
UPDATER="https://raw.githubusercontent.com/ODEX-TOS/system-updater/master/update.sh"


function help {
        printf "${ORANGE} $name ${NC}OPTIONS: difference | help | info | version\n\n" 
        printf "${ORANGE}USAGE:${NC}\n"
        printf "$name  \t\t\t Update your current system\n"
        printf "$name  --difference \t\t Show what is new in the latest tos version\n"
        printf "$name  --help \t\t\t Show this help message\n"
        printf "$name  --info \t\t\t Show your current tos version\n"
        printf "$name  --version \t\t Show information about this tool\n"
}

# print the current version of ths software
function version {
    printf "${ORANGE}TOS $name${NC} - Updating software\n${ORANGE}Version: ${NC}${version}\n"
}

# see what the new updates are
function difference {
    # get the raw datastream
    data=$(curl -fsSk "$LATEST_INFO_URL")

    # parse the data

    title=$(printf "$data" | grep -A 1 "\[Title\]" | sed 's:\[Title\]::g')
    features=$(printf "$data" | grep -A 1000 "\[New Features\]" | sed 's:\[New Features\]::g' | awk '{if($0 ~ /\[.*\]/){newfield=1;} if (!newfield){print $0}}')
    bugfixes=$(printf "$data" | grep -A 1000 "\[Bug fixes\]" | sed 's:\[Bug fixes\]::g' | awk '{if($0 ~ /\[.*\]/){newfield=1;} if (!newfield){print $0}}')

    # print the converted data
    printf "${ORANGE}%s${NC}\n\n" "$title"
    printf "${ORANGE}Features:${NC}%s\n\n" "$features"
    printf "${ORANGE}Bug Fixes:${NC}%s\n" "$bugfixes"
}

# update your system to the new tos version
function update {
    # get the blacklist from the config file
    if [[ -f "/etc/system-updater.conf" ]]; then
        blacklist="$(cat /etc/system-updater.conf | grep exclude.*= | cut -d= -f2 | sed 's:\s*::')"
    fi
    if [[ -f "system-updater.conf" ]]; then
        blacklist="$(cat system-updater.conf | grep exclude.*= | cut -d= -f2 | sed 's:\s*::')"
    fi
    
    # get the packages from the repo
    data=$(curl -fsSk "$PACKAGES")

    # filter all packages in the blacklist out of all packages
    for item in $blacklist; do
        data=$(printf "$data" | sed 's:'"$item"'::g')
    done

    installed=$(tos -Q | cut -d " " -f1)

    toInstall=""
    # Get all packages that are not installed
    for item in $data; do
        if ! echo "$installed" | grep -q "$item" ; then
            toInstall="$toInstall $item"
        fi 
    done

    tos -Syu $toInstall
    
    curl -fsSk "$UPDATER" | bash
}

function info {
    printf "Current tos version %s\n" "$(cat /etc/version)"
}

case "$1" in 
    "-v"|"--version")
        version
    ;;
    "-d"|"--difference")
        difference
    ;;
    "-i"|"--info")
        info
    ;;
    "-h"|"--help")
        help
    ;;
    "")
        difference
        # make sure the user is aware of the risk
        printf "\n\n${RED}This tool will alter your system. Make sure you have made a backup as some files/packages may change${NC}\n"
        read -p "Press enter to continue"
        update
    ;;
esac