#!/bin/bash

# color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;35m'
ORANGE='\033[1;33m'
NC='\033[0m' # No Color

name="system-updater"
version="v0.1"


function help {
        printf "${ORANGE} $name ${NC}OPTIONS: difference | help | info | version\n\n" 
        printf "${ORANGE}USAGE:${NC}\n"
        printf "$name  \t\t\t Update your current system\n"
        printf "$name  --difference \t\t Show what is new in the latest tos version\n"
        printf "$name  --help \t\t\t Show this help message\n"
        printf "$name  --info \t\t\t Show your current tos version\n"
        printf "$name  --version \t\t Show information about this tool\n"
}



function version {
    printf "${ORANGE}TOS $name${NC} - Updating software\n${ORANGE}Version: ${NC}${version}\n"
}

function difference {
    printf "Difference\n"
}

function update {
    printf "updating\n"
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
        update
    ;;
esac