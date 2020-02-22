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

printf "\n${RED}STARTING FILE ADJUSTMENT${NC}\n"

# MUST READ
# This script needs to be backwards compatible
# Always check if a file/directory already exists
# Don't forget that older installation might use file in other locations that expected
# For example the migration from the user .config directory to the systemwide /etc/xdg directory
# This required the deletion of the .config/awesome directory. This could have been a user that on purpose wrote scripts in this directory
# In other words if removing something ask for user permission such as this

# read -p "Migrating from .config/awesome to /etc/xdg/awesome. Are we allowed to delete .config/awesome. If not sure enter y (y/N)" answer

# This makes sure the end user doesn't get annoyed that there custom functionality suddenly disappeared


# Important to know: This file will be ran as the user not as root

# URLS
USERCHROME="https://raw.githubusercontent.com/ODEX-TOS/dotfiles/master/tos/tos-firefox/chrome/userChrome.css"
COLOR_CONF_URL="https://raw.githubusercontent.com/ODEX-TOS/dotfiles/master/tos/colors.conf"
ICONS_CONF_URL="https://raw.githubusercontent.com/ODEX-TOS/dotfiles/master/tos/icons.conf"
TAGS_CONF_URL="https://raw.githubusercontent.com/ODEX-TOS/dotfiles/master/tos/tags.conf"
FLOATING_CONF_URL="https://raw.githubusercontent.com/ODEX-TOS/dotfiles/master/tos/floating.conf"
TOS_COMPLETION="https://raw.githubusercontent.com/ODEX-TOS/tools/master/_tos"

# PATHS
SYSTEMD_DM_PATH="/etc/systemd/system/display-manager.service"

# log levels to be used with the log function
LOG_WARN="${ORANGE}[WARN]"
LOG_ERROR="${RED}[ERROR]"
LOG_INFO="${GREEN}[INFO]"
LOG_DEBUG="${BLUE}[DEBUG]"

ALTER="$1" # if this is set we don't alter the state of our machine

# $1 is the log type eg LOG_WARN, LOG_ERROR or LOG_NORMAL
function log {
        echo -e "$@ ${NC}"
}

# BEGIN COMPATIBILITY HERE

# modify all userChrome file to match the remote url
function alter-firefox-user-chrome {
    log "$LOG_INFO" "Downloading new userChrome.css file"
    data=$(curl -fSsk "$USERCHROME")
    log "$LOG_INFO" "Verifying the data"
    if [[ "$data" != "" ]]; then
            log "$LOG_INFO" "Downloaded file is valid. Applying patches"
        for chrome in $HOME/.mozilla/firefox/*/chrome/userChrome.css; do
            log "$LOG_INFO" "Altering $chrome"
            if [[ "$ALTER" == "" ]]; then
                    echo "$data" > "$chrome"
            fi 

        done
    else
            log "$LOG_ERROR" "Downloading userchrome.css failed from $USERCHROME"
    fi
}

# function used to alter the state of firefox
function prepare-firefox {
    log "$LOG_INFO" "Configuring firefox"
    log "$LOG_WARN" "We will be altering userChrome.css"
    read -p "Do you want to update firefox to the latest to version (y/N)" answer
    if [[ "$answer" == "y" || "$answer" == "Y" ]]; then
            log "$LOG_INFO" "Finding all userChrome.css files to update"
            alter-firefox-user-chrome
    else
            log "$LOG_INFO" "Not altering firefox"
    fi
}

# detect missing config files and add them when needed
function add-config {
    log "$LOG_INFO" "Detecting missing config files"
    COLORS_CONF="$HOME/.config/tos/colors.conf"
    ICONS_CONF="$HOME/.config/tos/icons.conf"
    TAGS_CONF="$HOME/.config/tos/tags.conf"
    FLOATING_CONF="$HOME/.config/tos/floating.conf"
    if [[ ! -f "$COLORS_CONF" ]]; then
        log "$LOG_INFO" "$COLORS_CONF is missing. It is used to alter the theme colors of your system"
        read -p "Do you want us to add colors.conf to your system (y/N)" answer
        if [[ "$answer" == "y" || "$answer" == "Y" ]]; then
                log "$LOG_INFO" "Downloading latest version of colors.conf"
                if [[ "$ALTER" == "" ]]; then
                        curl -fSsk "$COLOR_CONF_URL" -o "$COLORS_CONF"
                fi
        fi
    fi

    if [[ ! -f "$ICONS_CONF" ]]; then
        log "$LOG_INFO" "$ICONS_CONF is missing. It is used to alter the icons used by the system"
        read -p "Do you want us to add icons.conf to your system (y/N)" answer
        if [[ "$answer" == "y" || "$answer" == "Y" ]]; then
                log "$LOG_INFO" "Downloading latest version of icons.conf"
                if [[ "$ALTER" == "" ]]; then
                        curl -fSsk "$ICONS_CONF_URL" -o "$ICONS_CONF"
                fi
        fi
    fi

    if [[ ! -f "$TAGS_CONF" ]]; then
        log "$LOG_INFO" "$TAGS_CONF is missing. It is used to describe where new applications launch, Eg in which workspace"
        read -p "Do you want us to add tags.conf to your system (y/N)" answer
        if [[ "$answer" == "y" || "$answer" == "Y" ]]; then
                log "$LOG_INFO" "Downloading latest version of tags.conf"
                if [[ "$ALTER" == "" ]]; then
                        curl -fSsk "$TAGS_CONF_URL" -o "$TAGS_CONF"
                fi
        fi
    fi

    if [[ ! -f "$FLOATING_CONF" ]]; then
        log "$LOG_INFO" "$FLOATING_CONF is missing. It is used to describe which applications are draggable (not tiling)"
        read -p "Do you want us to add floating.conf to your system (y/N)" answer
        if [[ "$answer" == "y" || "$answer" == "Y" ]]; then
                log "$LOG_INFO" "Downloading latest version of floating.conf"
                if [[ "$ALTER" == "" ]]; then
                        curl -fSsk "$FLOATING_CONF_URL" -o "$FLOATING_CONF"
                fi
        fi
    fi
}

function group-add {
    if ! groups | grep -q "input"; then
        log "$LOG_INFO" "Adding user to the correct groups"
        read -p "Do you want use to add $USER to the input group? (y/N)" answer
        if [[ "$answer" == "y" || "$answer" == "Y" ]]; then
            log "$LOG_WARN" "Using elevated permissions to alter input group"
            sudo gpasswd -a "$USER" input
            log "$LOG_INFO" "Added $USER to input group"
            log "$LOG_INFO" "Logout to make these changes take effect"
        fi 
    else
        log "$LOG_INFO" "User groups seems correct"
    fi
}

function setup-greeter {
    if ! file "$SYSTEMD_DM_PATH" | grep -q "sddm.service"; then
        log "$LOG_INFO" "Setting up the new greeter"
        read -p "Would you like us to change the greeter to sddm (y/N)" answer
        if [[ "$answer" == "y" || "$answer" == "Y" ]]; then
            log "$LOG_WARN" "Changing the greeter to sddm"
            if [[ "$ALTER" == "" ]]; then
                sudo systemctl disable lightdm # disable the old greeter
                sudo systemctl enable sddm # enabeling the new greeter
            fi
            log "$LOG_WARN" "If your greeter is broken you need to do the following in a terminal"
            log "$LOG_WARN" "sudo systemctl disable sddm && sudo systemctl enable lightdm"
        fi
    else
        log "$LOG_INFO" "Official Display Manager SDDM is being used"
    fi
}

function tos-completion {
    log "$LOG_INFO" "Downloading latest tos completion script"
    if [[ -d "$HOME/.oh-my-zsh/custom/plugins/zsh-completions/src/" ]]; then
        if [[ "$ALTER" == "" ]]; then
            curl -fSsk "$TOS_COMPLETION" > "$HOME/.oh-my-zsh/custom/plugins/zsh-completions/src/_tos"
        fi
    else
        log "$LOG_ERROR" "Cannot add autocompletion for tos. Files are missing"
        log "$LOG_ERROR" "If you see this message don't worry your system should still work"
        log "$LOG_ERROR" "However there will be no shell autocompletion support for you"
    fi
}

function run {
        prepare-firefox # convert your firefox installation
        add-config # add missing configuration files
        group-add
        setup-greeter
        tos-completion
}

run




