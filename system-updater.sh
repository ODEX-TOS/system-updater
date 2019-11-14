#!/bin/bash


function help {

}

function version {

}

function difference {

}

function update {

}

function info {

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