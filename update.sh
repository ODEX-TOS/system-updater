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


# Important to know: This file will be ran as the user not as root

# URLS
USERCHROME="https://raw.githubusercontent.com/ODEX-TOS/dotfiles/master/tos/tos-firefox/chrome/userChrome.css"
USERCONTENT="https://raw.githubusercontent.com/ODEX-TOS/dotfiles/master/tos/tos-firefox/chrome/userContent.css"
FF_ADD="https://raw.githubusercontent.com/ODEX-TOS/dotfiles/master/tos/tos-firefox/chrome/add.svg"
FF_LARROW="https://raw.githubusercontent.com/ODEX-TOS/dotfiles/master/tos/tos-firefox/chrome/left-arrow.svg"
FF_RARROW="https://raw.githubusercontent.com/ODEX-TOS/dotfiles/master/tos/tos-firefox/chrome/right-arrow.svg"
COLOR_CONF_URL="https://raw.githubusercontent.com/ODEX-TOS/tos-desktop-environment/master/tos/colors.conf"
ICONS_CONF_URL="https://raw.githubusercontent.com/ODEX-TOS/tos-desktop-environment/master/tos/icons.conf"
TAGS_CONF_URL="https://raw.githubusercontent.com/ODEX-TOS/tos-desktop-environment/master/tos/tags.conf"
FLOATING_CONF_URL="https://raw.githubusercontent.com/ODEX-TOS/tos-desktop-environment/master/tos/floating.conf"
KEYS_CONF_URL="https://raw.githubusercontent.com/ODEX-TOS/tos-desktop-environment/master/tos/keys.conf"
GENERAL_CONF_URL="https://raw.githubusercontent.com/ODEX-TOS/tos-desktop-environment/master/tos/general.conf"
PLUGIN_CONF_URL="https://raw.githubusercontent.com/ODEX-TOS/tos-desktop-environment/master/tos/plugins.conf"
TOS_COMPLETION="https://raw.githubusercontent.com/ODEX-TOS/tools/master/_tos"

# lightdm configuration
LIGHTDM_CONF_URL="https://raw.githubusercontent.com/ODEX-TOS/lightdm-tde/master/lightdm.conf"
LIGHTDM_GREETER_URL="https://raw.githubusercontent.com/ODEX-TOS/lightdm-tde/master/lightdm-webkit2-greeter.conf"

# PATHS
SYSTEMD_DM_PATH="/etc/systemd/system/display-manager.service"

# log levels to be used with the log function
LOG_WARN="${ORANGE}[WARN]${NC}"
LOG_ERROR="${RED}[ERROR]${NC}"
LOG_INFO="${GREEN}[INFO]${NC}"
LOG_DEBUG="${BLUE}[DEBUG]${NC}"


ALTER="$1" # if this is set we don't alter the state of our machine
if [[ "$ALTER" == "--no-log" || "$ALTER" == "--no-interaction" ]]; then
    ALTER=""
fi
if [[ "$@" == *"--no-log"* ]]; then
        LOG_SUPRESS="1"
fi
if [[ "$@" == *"--no-interaction"* ]]; then
        NO_INTERACTION="1"
fi

if [[ "$LOG_SUPRESS" == "" ]]; then
    printf "$ALTER"
    printf "\n${RED}STARTING FILE ADJUSTMENT${NC}\n"
fi

SEND_STATS="${SEND_STATS:-1}"

# $1 is the log type eg LOG_WARN, LOG_ERROR or LOG_NORMAL
function log {
        if [[ "$LOG_SUPRESS" == "" ]]; then
            echo -e "$@"
        fi
}

# BEGIN COMPATIBILITY HERE

# modify all userChrome file to match the remote url
function alter-firefox-user-chrome {
    log "$LOG_INFO" "Downloading new userChrome.css file"
    data=$(curl -fSsk "$USERCHROME")
    data2=$(curl -fSsk "$USERCONTENT")
    log "$LOG_INFO" "Verifying the data"
    if [[ "$ALTER" == "" ]]; then
        cp -r /etc/skel/.mozilla/firefox/tos.default "$HOME"/.mozilla/firefox/
    fi
    if [[ "$data" != "" || "$data2" != "" ]]; then
        log "$LOG_INFO" "Downloaded file is valid. Applying patches"
        for chrome in $HOME/.mozilla/firefox/*/chrome/userChrome.css; do
            log "$LOG_INFO" "Altering $chrome"
            if [[ "$ALTER" == "" ]]; then
                    echo "$data" > "$chrome"
                    log "$LOG_INFO" "populated $chrome with correct data"
            fi 
        done
        for chrome in $HOME/.mozilla/firefox/*/chrome/userContent.css; do
            log "$LOG_INFO" "Altering $chrome"
            if [[ "$ALTER" == "" ]]; then
                    echo "$data2" > "$chrome"
                    log "$LOG_INFO" "populated $chrome with correct data"
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
    if [[ "$NO_INTERACTION" == "" ]]; then
        read -p "Do you want to update firefox to the latest to version (y/N)" answer
    else
            answer="y"
    fi
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
    KEYS_CONF="$HOME/.config/tos/keys.conf"
    GENERAL_CONF="$HOME/.config/tos/general.conf"
    PLUGIN_CONF="$HOME/.config/tos/plugins.conf"
    if [[ ! -f "$COLORS_CONF" ]]; then
        log "$LOG_INFO" "$COLORS_CONF is missing. It is used to alter the theme colors of your system"
        read -p "Do you want us to add colors.conf to your system (y/N)" answer
        if [[ "$answer" == "y" || "$answer" == "Y" ]]; then
                log "$LOG_INFO" "Downloading latest version of colors.conf"
                if [[ "$ALTER" == "" ]]; then
                        curl -fSsk "$COLOR_CONF_URL" -o "$COLORS_CONF"
                        log "$LOG_INFO" "$COLORS_CONF has been installed"
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
                        log "$LOG_INFO" "$ICONS_CONF has been installed"
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
                        log "$LOG_INFO" "$TAGS_CONF has been installed"
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
                        log "$LOG_INFO" "$FLOATING_CONF has been installed"
                fi
        fi
    fi
    if [[ ! -f "$KEYS_CONF" ]]; then
        log "$LOG_INFO" "$KEYS_CONF is missing. It is used to describe which the keyboard shortcuts"
        read -p "Do you want us to add keys.conf to your system (y/N)" answer
        if [[ "$answer" == "y" || "$answer" == "Y" ]]; then
                log "$LOG_INFO" "Downloading latest version of keys.conf"
                if [[ "$ALTER" == "" ]]; then
                        curl -fSsk "$KEYS_CONF_URL" -o "$KEYS_CONF"
                        log "$LOG_INFO" "$KEYS_CONF has been installed"
                fi
        fi
    fi
    if [[ ! -f "$GENERAL_CONF" ]]; then
        log "$LOG_INFO" "$GENERAL_CONF is missing. It describes how the Desktop Environment should behave"
        read -p "Do you want us to add general.conf to your system (y/N)" answer
        if [[ "$answer" == "y" || "$answer" == "Y" ]]; then
                log "$LOG_INFO" "Downloading latest version of general.conf"
                if [[ "$ALTER" == "" ]]; then
                        curl -fSsk "$GENERAL_CONF_URL" -o "$GENERAL_CONF"
                        log "$LOG_INFO" "$GENERAL_CONF has been installed"
                fi
        fi
    fi
    if [[ ! -f "$PLUGIN_CONF" ]]; then
        log "$LOG_INFO" "$PLUGIN_CONF is missing. It is used to enable/disable custom plugins"
        read -p "Do you want us to add plugins.conf to your system (y/N)" answer
        if [[ "$answer" == "y" || "$answer" == "Y" ]]; then
                log "$LOG_INFO" "Downloading latest version of plugins.conf"
                if [[ "$ALTER" == "" ]]; then
                        curl -fSsk "$PLUGIN_CONF_URL" -o "$PLUGIN_CONF"
                        log "$LOG_INFO" "$PLUGIN_CONF has been installed"
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
    log "$LOG_INFO" "Checking current active greeter"
    if ! file "$SYSTEMD_DM_PATH" | grep -q "lightdm.service"; then
        log "$LOG_INFO" "Setting up the new greeter"
        read -p "Would you like us to change the greeter to lightdm (y/N)" answer
        if [[ "$answer" == "y" || "$answer" == "Y" ]]; then
            log "$LOG_WARN" "Changing the greeter to lightdm"
            if [[ "$ALTER" == "" ]]; then
                sudo systemctl disable sddm # disable the old greeter
                sudo systemctl enable lightdm # enabeling the new greeter
                curl -fSsk "$LIGHTDM_CONF_URL" | sudo tee /etc/lightdm/lightdm.conf >/dev/null
                curl -fSsk "$LIGHTDM_GREETER_URL" | sudo tee /etc/lightdm/lightdm-webkit2-greeter.conf >/dev/null
            fi
            log "$LOG_WARN" "If your greeter is broken you need to do the following in a terminal"
            log "$LOG_WARN" "sudo systemctl disable lightdm && sudo systemctl enable sddm"
        fi
    else
        log "$LOG_INFO" "Official Display Manager lightdm is being used"
    fi
}

function tos-completion {
    log "$LOG_INFO" "Preparing TOS completion scripts"
    if [[ -d "$HOME/.oh-my-zsh/custom/plugins/zsh-completions/src/" ]]; then
        if [[ "$ALTER" == "" ]]; then
            log "$LOG_INFO" "Downloading latest tos completion script"
            curl -fSsk "$TOS_COMPLETION" > "$HOME/.oh-my-zsh/custom/plugins/zsh-completions/src/_tos"
            log "$LOG_INFO" "TOS completion scripts have been installed"
        fi
    else
        log "$LOG_ERROR" "Cannot add autocompletion for tos. Files are missing"
        log "$LOG_ERROR" "If you see this message don't worry your system should still work"
        log "$LOG_ERROR" "However there will be no shell autocompletion support for you"
    fi
}

# enable sysrq triggers
function sysrq-trigger {
    log "$LOG_INFO" "Enabling sysrq triggers for the current session"
    if [[ "$ALTER" == "" ]]; then
        [[ "$(cat /proc/sys/kernel/sysrq 2>/dev/null )" == "511" ]] || echo "511" | sudo tee /proc/sys/kernel/sysrq 1>/dev/null
    fi
    log "$LOG_INFO" "Sysrq trigger has been configured for this session"
    log "$LOG_INFO" "Setting up persistent sysrq triggers between reboots"
    if [[ "$ALTER" == "" ]]; then
        if [[ ! -d "/etc/sysctl.d" ]]; then
            sudo mkdir -p /etc/sysctl.d
        fi
        [[ "$(cat /etc/sysctl.d/99-sysctl.conf 2>/dev/null )" == "kernel.sysrq = 511" ]] || echo "kernel.sysrq = 511" | sudo tee /etc/sysctl.d/99-sysctl.conf 1>/dev/null
        log "$LOG_INFO" "Sysrq setting have been globally applied"
    fi

}

# changed default icon theme to papirus instead of mcmojave
function icon-theme {
    log "$LOG_INFO" "Detecting gtk 3.0 icon theme"
    theme="$(grep gtk-icon-theme-name $HOME/.config/gtk-3.0/settings.ini | awk -F= '{printf $2}')"
    if [[ "$theme" == *"mojave-circle"* ]]; then
        log "$LOG_WARN" "You are using an old mcmojave theme. It is no longer supported"
        read -p "Would you like to change to the papirus theme? (y/N)" answer
        if [[ "$answer" == "y" || "$answer" == "Y" ]]; then
            log "$LOG_INFO" "Changing the theme to papirus-dark"
            if [[ "$ALTER" == "" ]]; then
                sed -i 's:gtk-icon-theme-name=.*$:gtk-icon-theme-name=Papirus-Dark:g' "$HOME/.config/gtk-3.0/settings.ini"
                log "$LOG_INFO" "Updated icon theme. Logout to take effect"
            fi
        fi
    fi
}

function kernel-hook {
    log "$LOG_INFO" "Checking kernel module hook daemon"
    if [[ -f "/usr/lib/systemd/system/linux-modules-cleanup.service" ]]; then
            log "$LOG_INFO" "Kernel hook service found!"
            log "$LOG_INFO" "Setting hook as enabled"
            if [[ "$ALTER" == "" ]]; then
                    sudo systemctl daemon-reload
                    sudo systemctl enable linux-modules-cleanup
            fi
    else
            log "$LOG_WARN" "kernel module hook not found. We recommend you to install kernel-modules-hook from the tos repository (tos -Syu kernel-modules-hook)"
    fi
}

function services {
    log "$LOG_INFO" "Checking to see if certain services are working"
    if lsblk --discard | awk 'NR!=1&&$3!="0B"&&$4!="0B"{print $3, $4}' | grep -qE '[0-9]*[TGMKB]'; then
        log "$LOG_INFO" "Detected ssd trim capabilities"
        log "$LOG_INFO" "Enabling ssd trim timer"
        if [[ "$ALTER" == "" ]]; then 
            # only enable the timer if it is disabled
            systemctl status --no-pager fstrim.timer &>/dev/null || systemctl enable --now fstrim.timer
        fi
    else
            log "$LOG_WARN" "Your hardware doesn't support trimming"
            log "$LOG_WARN" "We won't enable the systemctl service"
            log "$LOG_WARN" "If you do want this capability then we suggest to use an ssd with trim functionality"
    fi
    log "$LOG_INFO" "Checking package stats service timer"
    if ! systemctl is-active --quiet pkgstats.timer; then
            log "$LOG_INFO" "Timer is not running. Enabling it now"
            if [[ "$ALTER" == "" && "$SEND_STATS" == "1" ]]; then
                systemctl enable --now pkgstats.timer
                log "$LOG_INFO" "Enabled pkgstats timer"
            fi
    fi
}

function etc-issue {
    log "$LOG_INFO" "Updating /etc/issue"
    if [[ "$ALTER" == "" ]]; then
        [[ "$(cat /etc/issue 2>/dev/null )" == "TOS Linux \r (\l)" ]] || printf "TOS Linux \\\\r (\\\\l)\n" | sudo tee /etc/issue 1>/dev/null
    fi
}

function add-default-plugins {
    plug="$HOME/.config/tde/"
    log "$LOG_INFO" "Checking default plugins in $plug"
    if [[ "$ALTER" == "" ]]; then
        # check if /etc/skel/.config/tde exists
        # if it does then copy over those files
        if [[ -d "/etc/skel/.config/tde" ]]; then
            log "$LOG_INFO" "Copying over default plugins"
            [[ ! -d "$HOME/.config/tde" ]] && mkdir -p "$HOME/.config/tde"
            cp -r "/etc/skel/.config/tde/"* "$HOME/.config/tde/"
        else
            log "$LOG_WARN" "TDE configs are not present in skel. Make sure skel is installed and/or is up to date."
        fi
    fi
}

# we changed the default image
# If we detect that the user is using it we must change it to the new version
function fix-default-image {
    theme="$HOME/.config/tos/theme"
    if [[ -f "$theme"  && -f "/usr/share/backgrounds/tos/default.jpg" ]]; then
            if grep -q "/usr/share/backgrounds/tos/default.png" "$theme"; then
                log "$LOG_INFO" "We recently changed the default wallpaper from default.png to default.jpg to reduce disk space"
                if [[ "$ALTER" == "" ]]; then
                    sed -i 's;/usr/share/backgrounds/tos/default.png;/usr/share/backgrounds/tos/default.jpg;g' "$theme"
                fi
            fi
    fi
}

# configure some pacman options to be one by default
function pacman-conf {
    _CONF="/etc/pacman.conf"
    if grep -q "#Color" "$_CONF"; then
        log "$LOG_INFO" "Enabling package manager color mode."
        if [[ "$ALTER" == "" ]]; then
            sudo sed -i 's/#Color/Color/g' "$_CONF"
        fi
    fi 
    if grep -q "#TotalDownload" "$_CONF"; then
        log "$LOG_INFO" "Enabling package manager total download mode."
        if [[ "$ALTER" == "" ]]; then
            sudo sed -i 's/#TotalDownload/TotalDownload/g' "$_CONF"
        fi
    fi 
    if ! grep -q "^ILoveCandy" "$_CONF"; then
        log "$LOG_INFO" "Package Updater backend renderer changed."
        if [[ "$ALTER" == "" ]]; then
            sudo sed -i 's/TotalDownload/TotalDownload\nILoveCandy/g' "$_CONF"
        fi
    fi 
}

# check if the zsh-completion plugin is installed
function zsh-completion-plugin {
    # download plugin section
    COMPLETION_DIR="$HOME/.oh-my-zsh/custom/plugins/zsh-autocomplete"
    if [[ -d "$COMPLETION_DIR" ]]; then
        log "$LOG_INFO" "ZSH autocomplete is already installed and configured"
        return 
    fi
    log "$LOG_INFO" "Installing zsh-autocompletion function"
    if [[ "$ALTER" == "" ]]; then 
        git clone https://github.com/marlonrichert/zsh-autocomplete.git "$COMPLETION_DIR"
    fi
   
    # enable plugin section

    PLUGIN_FILE="$HOME/.oh-my-zsh/load/preload/plugins.sh"
    if grep -q "zsh-autocomplete" "$PLUGIN_FILE"; then
        log "$LOG_INFO" "Plugin enabled, reload terminal to take affect"
        return
    fi

	if [[ "$ALTER" == "" ]]; then
		sed -i 's/plugins=(/plugins=(\n  zsh-autocomplete/g' "$PLUGIN_FILE"
	fi

    log "$LOG_INFO" "Plugin enabled, reload terminal to take affect"

    # configure the plugin

    PLUGIN_CONF="$HOME/.oh-my-zsh/load/preload/config.sh"

    log "$LOG_INFO" "Setting TAB key to cycle through the menu"

    if grep -q "zstyle ':autocomplete:tab:*' widget-style menu-select" "$PLUGIN_CONF"; then
        sed -i 's/widget-style menu-select/widget-style menu-complete/g'
        return
    fi

    if grep -q "zstyle ':autocomplete:tab:*' widget-style menu-complete" "$PLUGIN_CONF"; then
        log "$LOG_INFO" "Plugin already configured"
        return
    fi
    
    if [[ "$ALTER" == "" ]]; then
        echo "zstyle ':autocomplete:tab:* widget-style menu-complete'" >> "$PLUGIN_CONF"
    fi
    log "$LOG_INFO" "ZSH plugin configured"
}

function zsh-syntax-highlight {
    PLUGIN_FILE="$HOME/.oh-my-zsh/load/preload/plugins.sh" 
    if grep -q "fast-syntax-highlighting" "$PLUGIN_FILE"; then
        return
    fi

    log "$LOG_INFO" "Changing zsh syntax highlighter from zsh-syntax to fast-syntax"
    if [[ "$ALTER" == "" ]]; then
        sed -i 's;zsh-syntax-highlighting;fast-syntax-highlighting;g' "$PLUGIN_FILE"
    fi


    COMPLETION_DIR="$HOME/.oh-my-zsh/custom/plugins/fast-syntax-highlighting"
    if [[ -d "$COMPLETION_DIR" ]]; then
        return
    fi
    
    log "$LOG_INFO" "Downloading new plugin"
    if [[ "$ALTER" == "" ]]; then
        git clone https://github.com/marlonrichert/fast-syntax-highlighting.git "$COMPLETION_DIR"
    fi

    log "$LOG_INFO" "Finished setting up syntax highlighting plugin"
}

function fonts {
        FONT_CONF="$HOME/.config/fontconfig/fonts.conf"
        log "$LOG_INFO" "Updating fonts"
        if [[ "$ALTER" == "" ]]; then
            sed -i 's;Linux Libertine;Liberation Serif;g' "$FONT_CONF"
            sed -i 's;Linux Biolinum;Ubuntu;g' "$FONT_CONF"
        fi
}

function touchegg-systemd {
    log "$LOG_INFO" "Checking touchegg status"
    if ! systemctl is-active touchegg &>/dev/null; then
        log "$LOG_INFO" "Enabling touchegg"
        if [[ "$ALTER" == "" ]]; then
            sudo systemctl enable --now touchegg
        fi
    fi
}

function check_qt_5_theme {
    log "$LOG_INFO" "Checking qt5 theme status"
    kvantum_conf="$HOME/.config/Kvantum"
    qt5ct_conf="$HOME/.config/qt5ct"
    if [[ ! -d "$kvantum_conf" ]]; then
        log "$LOG_INFO" "Kvantum theme configuration is not present. Generating..."
        [[ "$ALTER" == "" ]] && cp -r "/etc/skel/.config/Kvantum" "$HOME/.config"
    fi

    if [[ ! -d "$qt5ct_conf" ]]; then
        log "$LOG_INFO" "QT5CT configuration is not present. Generating..."
        [[ "$ALTER" == "" ]] && cp -r "/etc/skel/.config/qt5ct" "$HOME/.config"
    fi
}

function reflector_timer {
        if ! systemctl is-active reflector.timer &>/dev/null; then
            log "$LOG_INFO" "Not syncing the fastest repository."
            if [[ "$ALTER" == "" ]]; then
                log "$LOG_INFO" "Manually syncing speed"
                sudo reflector --verbose --latest 5 --sort rate --save /etc/pacman.d/mirrorlist
                log "$LOG_INFO" "Sorted the fastest mirrors"
                log "$LOG_INFO" "Enabling weekly sync timer"
                sudo systemctl enable reflector.timer
            fi
        else
            log "$LOG_INFO" "Syncing mirrors is enabled"
        fi
}

function grc_colorizer {
        log "$LOG_INFO" "Checking colorizer status"
        if ! grep -q "source /etc/grc.zsh" "$HOME/.oh-my-zsh/load/etc.sh"; then
                log "$LOG_INFO" "colorized utilities not found, enabling setting"
                echo "if [[ -f "/etc/grc.zsh" ]]; then" >> "$HOME/.oh-my-zsh/load/etc.sh"
                echo "  source /etc/grc.zsh" >> "$HOME/.oh-my-zsh/load/etc.sh"
                echo "fi" >> "$HOME/.oh-my-zsh/load/etc.sh"
                log "$LOG_INFO" "grc is enabled"
        fi
}

function pacman_6_total_download () {
	log "$LOG_INFO" "Checking /etc/pacman.conf"	
	if grep -q "TotalDownloads" /etc/pacman.conf; then
		log "$LOG_WARN" "Misconfigured pacman.conf, pacman 6 will not work properly, fixing..."
		sudo sed -i 's/TotalDownload//g' /etc/pacman.conf
	fi

	# check if pacman support parallel downloads
	local major_version="$(pacman -Q pacman | cut -d' ' -f2 | cut -d'.' -f1)"
	if [[ "$major_version" -gt "5" && "$(! grep -q ParallelDownloads /etc/pacman.conf)" ]]; then
		log "$LOG_INFO" "Fresh pacman 6 found, enabeling parallel downloads"
		sudo sed -i 's/Color/Color\nParallelDownloads = 5/g' /etc/pacman.conf
	fi

}

function run {
        prepare-firefox # convert your firefox installation
        fix-default-image
        add-config # add missing configuration files
        add-default-plugins
        group-add
        setup-greeter
        tos-completion
        icon-theme
        sysrq-trigger
        kernel-hook
        services
        etc-issue
        pacman-conf
        zsh-completion-plugin
        zsh-syntax-highlight
        fonts
        touchegg-systemd
        check_qt_5_theme
        reflector_timer
        grc_colorizer
	pacman_6_total_download
}   

run




