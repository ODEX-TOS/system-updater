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
version="v0.2"

LATEST_INFO_URL="https://raw.githubusercontent.com/ODEX-TOS/system-updater/master/tos-latest.info"
PACKAGES="https://raw.githubusercontent.com/ODEX-TOS/system-updater/master/packages"
UPDATER="https://raw.githubusercontent.com/ODEX-TOS/system-updater/master/update.sh"
CONFLICT="https://raw.githubusercontent.com/ODEX-TOS/system-updater/master/conflicts.sh"
NEW_VERSION_URL="https://raw.githubusercontent.com/ODEX-TOS/tos-live/master/toslive/version-edit.txt"

# log levels to be used with the log function
LOG_WARN="${ORANGE}[WARN]"
LOG_ERROR="${RED}[ERROR]"
LOG_INFO="${GREEN}[INFO]"
LOG_DEBUG="${BLUE}[INFO]"
LOG_VERSION="${BLUE}[VERSION]"

# cache data
CACHE_DIR="$HOME/.cache/tos-updater"

[[ -d "$CACHE_DIR" ]] || mkdir -p "$CACHE_DIR"

# $1 is the log type eg LOG_WARN, LOG_ERROR or LOG_NORMAL
function log {
        echo -e "$@ ${NC}"
}


function help {
        printf "${ORANGE}$name ${NC}OPTIONS: cache | difference | help | info | inspect | version\n\n" 
        printf "${ORANGE}USAGE:${NC}\n"
        printf "\t$name  \t\t\t Update your current system\n"
        printf "\t$name  --cache (-c)\t\t Clear out the generated cache data (this action cannot be reverted)\n"
        printf "\t$name  --difference (-d)\t Show what is new in the latest tos version\n"
        printf "\t$name  --help (-h)\t\t Show this help message\n"
        printf "\t$name  --info (-i)\t\t Show your current tos version\n"
        printf "\t$name  --inspect (-I)\t\t Inspect the updater script to make sure everything is safe\n"
        printf "\t$name  --version (-v)\t\t Show information about this tool\n"
}

# print the current version of ths software
function version {
    printf "${ORANGE}TOS $name${NC} - Updating software\n${ORANGE}Version: ${NC}${version}\n"
}

# see what the new updates are
function difference {
    # get the raw datastream
    data=$(curl -fsS "$LATEST_INFO_URL")

    # find all sections 
    OLDIFS="$IFS"
    IFS=$'\n' # bash specific
    for submenu in $(printf "$data" | grep '\[.*\]'); do
        escaped_submenu=$(printf "$submenu" | sed -e 's:\[:\\[:g' -e 's:\]:\\]:g')
        # format all data from the entire section
        section=$(printf "$data" | grep -A 1000 "$escaped_submenu" | sed "s:$escaped_submenu::g" | awk '{if($0 ~ /\[.*\]/){newfield=1;} if (!newfield){print $0}}')
        # filter out all duplicates
        section=$(( echo "$section"; cat "$CACHE_DIR/$submenu" 2>/dev/null ) | sort | uniq -u)
        printf "${ORANGE}%s${NC}%s\n\n" "$submenu" "$section"
        [[ -d "/tmp/tos-update/" ]] || mkdir -p "/tmp/tos-update"
        # save the current state of the update to a tmp file
        # Once the update is succesfull we can commit the data
        echo "$section" >>  "/tmp/tos-update/$submenu"

        
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
    data=$(curl -fsS "$PACKAGES")

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

    checkArchConflicts

    tos -Syu $toInstall
   
    executable=$(mktemp) 
    curl -fsS "$UPDATER" -o "$executable"
    bash "$executable"
    rm "$executable"

    commit

    # installation is successfull, updating version
    log "$LOG_WARN" "Updating your system version number requires root permissions"
    sudo curl -fsS "$NEW_VERSION_URL" -o /etc/version
    log "$LOG_VERSION" "$(cat /etc/version)"
}

function commit {
    # commiting the /tmp/tos-updater/* transactions
    log "$LOG_INFO" "Commiting system update information"
    OLDIFS="$IFS"
    IFS=$'\n' # bash specific
    for file in $(find /tmp/tos-update -type f); do
        name=$(basename "$file")
        # title should not get filtered
        [[ "$file" != "[Title]" ]] && cat "$file" >> "$CACHE_DIR/$name"
    done
    clear-tmp
    IFS="$OLDIFS"
    log "$LOG_INFO" "System update information succesfully logged to $CACHE_DIR"
}

function clear-tmp {
    [[ -d "/tmp/tos-update" ]] && rm -rf "/tmp/tos-update"
}

# interactivally clearing the cache
function clear-cache {
    CACHE_SIZE=$(du -smh "$CACHE_DIR" | cut -f1)
    TMP_SIZE=$(( du -smh "/tmp/tos-update" 2>/dev/null || echo "0B" ) | cut -f1 )

    log "$LOG_WARN" "Clearing out the cache ($CACHE_SIZE) and tmp files ($TMP_SIZE)"
    if [[ "$1" != "" ]]; then
        clear="Yes"
    else
        log "$LOG_WARN" "This action cannot be reverted are you sure (y/N)"
        read clear
    fi
    case "$clear" in
        "y"|"Y"|"yes" | "Yes")
            clear-tmp
            [[ -d "$CACHE_DIR" ]] && rm -rf "$CACHE_DIR"
        ;;
    esac
}

function checkArchConflicts {
    executable=$(mktemp)
    curl -fsS "$CONFLICT" -o "$executable"
    bash "$executable"
    rm "$executable"
}

function inspect {
    log "$LOG_INFO" "Downloading the package conflict script"
    curl -s "$CONFLICT"
    log "$LOG_INFO" "Check the above script to make sure everything seems normal. Once verified press enter"
    read -p ""
    log "$LOG_INFO" "Downloading latest update script"
    curl -s "$UPDATER"
    log "$LOG_INFO" "Check the above script to make sure everything seems normal"
}

function info {
    log "$LOG_INFO" "Current tos version: ${ORANGE}$(cat /etc/version)${NC}"
    log "$LOG_INFO" "Newest version: ${ORANGE}$(curl -fsS $NEW_VERSION_URL)${NC}"
}

case "$1" in 
    "-v"|"--version")
        version
    ;;
    "-d"|"--difference")
        difference
        clear-tmp
    ;;
    "-i"|"--info")
        info
    ;;
    "-I"|"--inspect")
        inspect
    ;;
    "-c"|"--cache")
        clear-cache "$2"
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
