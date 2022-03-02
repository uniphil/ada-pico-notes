#!/bin/bash
set -euo pipefail

msg() {
    word="${1-}"; shift
    case "$word" in
        Connect | Close)                COLOR='1;35' ;;  # green
        Setup | Build | Flash | Skip)   COLOR='1;36' ;;  # cyan
        Upload | Download)              COLOR='1;33' ;;  # yellow
        Skip)                           COLOR='1;31' ;;  # red
        -?*)                            COLOR='1;37' ;;  # white
    esac
    echo -e " \033[1;37m-> \033[1m\033[${COLOR}m${word}\033[1;37m ${*-}\033[0m"
}

etab() {
    if [ -t 1 ]
        then sed 's/^/      /'
        else cat
    fi
}

run() {
    cmd="${1-}"; shift
    echo -e "    \033[1;37m+ \033[1m\033[1;37m${cmd}\033[0m ${*}"
    $cmd "$@" | etab
}
