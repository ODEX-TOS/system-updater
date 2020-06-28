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

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;35m'
ORANGE='\033[1;33m'
NC='\033[0m' # No Color

# MUST READ
# This script needs to be backwards compatible
# Always check if a file/directory already exists
# Don't forget that older installation might use file in other locations that expected
# For example the migration from the user .config directory to the systemwide /etc/xdg directory
# This required the deletion of the .config/awesome directory. This could have been a user that on purpose wrote scripts in this directory
# In other words if removing something ask for user permission such as this

# read -p "Migrating from .config/awesome to /etc/xdg/awesome. Are we allowed to delete .config/awesome. If not sure enter y (y/N)" answer

# This makes sure the end user doesn't get annoyed that there custom functionality suddenly disappeared

# log levels to be used with the log function
LOG_WARN="${ORANGE}[WARN]${NC}"
LOG_ERROR="${RED}[ERROR]${NC}"
LOG_INFO="${GREEN}[INFO]${NC}"
LOG_DEBUG="${BLUE}[DEBUG]${NC}"

ALTER="$1" # if this is set we don't alter the state of our machine
if [[ "$ALTER" == "--no-log" ]]; then
        ALTER=""
fi
if [[ "$@" == *"--no-log"* ]]; then
        LOG_SUPRESS="1"
fi

# $1 is the log type eg LOG_WARN, LOG_ERROR or LOG_NORMAL
function log {
        if [[ "$LOG_SUPRESS" == "" ]]; then
            echo -e "$@"
        fi
}
# helper function to see if a version is older then $2
# the package name is $1
# if that is the case we echo $3
function version-check {
    if [[ "$1" == "" ]]; then
            exit 1
    fi
    if [[ "$2" == "" ]]; then
            exit 1
    fi
    installed=$(pacman -Qi "$1" 2>/dev/null | grep "Version" | awk '{printf $3}' || return)
    if [[ "$installed" ==  "$2" || "$installed" == "" ]]; then
            return
    fi
    if [[ "$installed" == "$(echo $2'\n'$installed | sort | head -n1 | tr -d '\n')" ]]; then
            echo "$3"
            return
    fi
}

# check if the correct keyring is installed
# if it is not NO tos package will be able to be installed
function keyring {
   if ! pacman -Qq | grep -q "tos-keyring" ; then
           log "$LOG_WARN" "No tos keyring found"
           log "$LOG_WARN" "All subsequent updates will fail unless a keyring is present"
           log "$LOG_WARN" "Downloading and preparing the keyring"
           fake-keyring || exit 1
           sudo pacman -U "https://repo.odex.be/tos-keyring-20200422-1-any.pkg.tar.zst" || exit 1
           log "$LOG_INFO" "Keyring installed"
   fi 
}

function fake-keyring {
    keys=$(curl -fSsk "https://raw.githubusercontent.com/ODEX-TOS/tos-live/master/repo/BUILD/KEYRING/tos.gpg")
    revoked=$(curl -fSsk "https://raw.githubusercontent.com/ODEX-TOS/tos-live/master/repo/BUILD/KEYRING/tos-revoked")
    trusted=$(curl -fSsk "https://raw.githubusercontent.com/ODEX-TOS/tos-live/master/repo/BUILD/KEYRING/tos-trusted")
    echo "$keys" | sudo tee /usr/share/pacman/keyrings/temp.gpg &>/dev/null
    echo "$revoked" | sudo tee /usr/share/pacman/keyrings/temp-revoked &>/dev/null
    echo "$trusted" | sudo tee /usr/share/pacman/keyrings/temp-trusted &>/dev/null
    sudo /usr/bin/pacman-key --populate temp
}

function cleanup-keyring {
    dir="/usr/share/pacman/keyrings"
    if [[ -f "$dir/temp.gpg" ]]; then
       sudo rm "$dir/temp.gpg"
    fi
    if [[ -f "$dir/temp-revoked" ]]; then
       sudo rm "$dir/temp-revoked"
    fi
    if [[ -f "$dir/temp-trusted" ]]; then
       sudo rm "$dir/temp-trusted"
    fi

}

function replace-package {
    if [[ "$1" == "" || "$2" == "" ]]; then
            exit 1
    fi
    if pacman -Q | grep -q "$1" ; then
            echo "$2"
    fi
}

function run {
        keyring
        # packages to check the version of
        # if the installed version is below a required version then we will perform a custom override to fix the issue
        out=$(echo "$(version-check 'nss' '3.51.1-1' '--overwrite /usr/lib\*/p11-kit-trust.so')") # date: 2020-04-13
        out=$(echo "$out" "$(version-check 'zn_poly' '0.9.2-2' '--overwrite /usr/lib/libzn_poly-0.9.so')") # date: 2020-04-14
        out=$(echo "$out" "$(version-check 'hplip' '3.20.3-2' '--overwrite /usr/share/hplip/\*')") # date: 2020-03-19
        out=$(echo "$out" "$(version-check 'firewalld' '0.8.1_2' '/usr/lib/python3.8/site-packages/firewall/\*')") # date: 2020-03-01

        out=$(echo "$out" "$(replace-package 'compton-tryone-tos' 'picom-tryone-tos')")

        log "$LOG_INFO" "The calculated command to update your system has been resolved to"
        log "$LOG_WARN" "pacman -Syu --noconfirm $out"
        if [[ "$ALTER" == "" &&  -z "$out" ]]; then
                log "$LOG_INFO" "root privileges are required to update the system packages"
                sudo pacman -Syu --noconfirm $out || (log "$LOG_ERROR" "Updating the system failed. Check https://www.archlinux.org/ for the latest news"; exit 1)
                log "$LOG_INFO" "Update is successful!"
        fi
        cleanup-keyring
}

run
