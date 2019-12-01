#!/bin/bash

# MIT License
# 
# Copyright (c) 2019 Meyers Tom
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

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
NEW_VERSION_URL="https://raw.githubusercontent.com/ODEX-TOS/tos-live/master/toslive/version-edit.txt"

# log levels to be used with the log function
LOG_WARN="${ORANGE}[WARN]"
LOG_ERROR="${RED}[ERROR]"
LOG_INFO="${GREEN}[INFO]"
LOG_DEBUG="${BLUE}[INFO]"
LOG_VERSION="${BLUE}[VERSION]"

# $1 is the log type eg LOG_WARN, LOG_ERROR or LOG_NORMAL
function log {
        echo -e "$@ ${NC}"
}


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

    # find all sections 
    OLDIFS="$IFS"
    IFS=$'\n' # bash specific
    for submenu in $(printf "$data" | grep '\[.*\]'); do
        escaped_submenu=$(printf "$submenu" | sed -e 's:\[:\\[:g' -e 's:\]:\\]:g')
        section=$(printf "$data" | grep -A 1000 "$escaped_submenu" | sed "s:$escaped_submenu::g" | awk '{if($0 ~ /\[.*\]/){newfield=1;} if (!newfield){print $0}}')
        printf "${ORANGE}%s${NC}%s\n\n" "$submenu" "$section"
    done
    IFS="$OLDIFS"
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
   
    executable=$(mktemp) 
    curl -fsSk "$UPDATER" -o "$executable"
    bash "$executable"
    rm "$executable"

    # installation is successfull, updating version
    log "$LOG_WARN" "Updating your system version number requires root permissions"
    sudo curl -fsSk "$NEW_VERSION_URL" -o /etc/version
    log "$LOG_VERSION" "$(cat /etc/version)"
}

function info {
    log "$LOG_INFO" "Current tos version: ${ORANGE}$(cat /etc/version)${NC}"
    log "$LOG_INFO" "Newest version: ${ORANGE}$(curl -fsSk $NEW_VERSION_URL)${NC}"
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
        printf "\n\n${ORANGE}[WARN] This tool will alter your system. Make sure you have made a backup as some files/packages may change${NC}\n"
        read -p "Press enter to continue"
        if [[ "$(id -u)" == "0" ]]; then
            printf "\n${RED}[ERROR] Running this as root is very dangerous. We will ask you for permission when needed${NC}\n"
            exit 1
        fi
        update
    ;;
esac
