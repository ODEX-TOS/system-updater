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

# This script performs checks to see if we should perform a system update or not
# The checks should see if the system is possible to perform updates on
# If it can't find things like the package manager it will abort the installation/update
# If it detects packages that need updates that will break the system it will abort

# call this function to abort the install
# $1 is the abort message send to system-updater
function abort {
    printf "%s" "$1"
    exit 1
}

function check-pacman {
    if [[ "$(command -v pacman)" == "" ]]; then
            abort "This system doesn't contain the correct package manager"
    fi
}

# check if $1 is installed on the system
# format can either be repo/package or package
function check-package-installed {
    repo=$(printf "$1" | cut -d "/" -f1)
    package=$(printf "$1" | cut -d "/" -f2)
    if ! pacman -Sl | grep -Eq "$repo $package.*\[installed\]"; then
            abort "package $1 is not installed on the system. $2"
    fi
}

function check-rofi-tos {
    repo="tos"
    package="rofi-tos"
    if ! pacman -Sl | grep -Eq "$repo $package.*\[installed\]"; then
            # remove the old rofi
            sudo pacman -Rns awesome-tos tos-tools rofi
            # install the packages again
            sudo pacman -Syu awesome-tos || exit 1
    fi
}


function run {
    check-pacman
    #check-package-installed "tos/filesystem" "Installing it will remove your passwords.\nMake sure you have a shell with root privileges and execute the following command\nfind /etc -type f -name '*.pacsave' -exec rename -d ''.pacsave' {} +\nAfter installing this package or you will not be able to log in again."
    check-rofi-tos

    # everything went well. Notifying the user
    printf "pre-check is a success"
    exit 0
}



run
