#!/bin/bash

set -u

screenid="memwatcher"
memfile="/tmp/memwatch.out"
lockfile="/tmp/memwatch.lock"
polltime=0.2
timeout=0.5

exit_status=0

ce="\033[0;31m$(tput bold)"
e="\033[0m$(tput sgr0)"

if [[ ${#@} == 0 ]]; then
    echo -e "${ce}At least 1 option is required, but found ${#arg}!${e}".
    echo "Use '--help' for more info"
    exit 1
fi

regex="/^Mem.*/!d ; s/^Mem[^0-9]+([0-9]+)[^0-9]+([0-9]+)[^0-9]+([0-9]+)[^0-9]+([0-9]+)[^0-9]+([0-9]+)[^0-9]+([0-9]+)$/\2/g"

function fn_start() {
    if ! screen -ls | grep -q "[0-9]*\.$screenid"; then
        echo $(free | sed -E "$regex") > "${memfile}"
        screen -DmS "$screenid" $0 --run &
        return 0
    fi
    return 1
}

function fn_stop() {
    for session in $(screen -ls | grep -o "[0-9]*\.$screenid"); do
        screen -S "${session}" -X quit
    done
    rm -f "${memfile}"
    rm -f "${lockfile}"
    return 0
}

function fn_run() {
    trap "rm -f $memfile" EXIT
    trap "rm -f $lockfile" EXIT
    while true; do
        curmem=$(free | sed -E "$regex")
        exec {fd}<>"$lockfile"
        if ! flock -x -n $fd; then
            prevmem=$(cat "$memfile")
            maxmem=$(( curmem > prevmem ? curmem : prevmem ))
            echo "$maxmem" > "$memfile"
            flock -u $fd
        fi
        sleep $polltime
    done
    return 0
}

function fn_reset() {
    if screen -ls | grep -q "No Sockets found"; then
        return 0
    fi
    curmem=$(free | sed -E "$regex")
    exec {fd}<>"$lockfile"
    nolock=$(flock -x -w $timeout $fd)
    echo "${curmem}" > "${memfile}"
    ((${nolock})) || flock -u $fd
    return ${nolock}
}

function fn_read() {
    # Attempt to use a lock. If it fails, attempt an unsafe read operation.
    exec {fd}<>"$lockfile"
    nolock=$(flock -s -w $timeout $fd)
    if [[ -f "$memfile" ]]; then
        cat "$memfile"
    else
        echo "0"
    fi
    ((${nolock})) || flock -u $fd
    return ${nolock}
}

# First check for '--help'. Print and exit if found.
for arg in "$@"; do
    if [[ "$arg" == "--help" ]]; then
        echo "USAGE: ./$(basename $0) [OPTIONS]"
        echo ""
        echo "  --help   Displays this help and exits afterwards."
        echo ""
        echo "  --start  Starts the memory watcher in a screen session."
        echo "           Only one screen session will be started."
        echo "  --stop   Stops the memory watcher running in a screen session started with '--start'."
        echo "  --reset  Resets the maximum memory value found so far."
        echo "  --read   Prints the maximum memory value found so far."
        echo "  --run    Runs the memory watcher in the current thread. Note that '--stop' does no"
        echo "           longer stop this execution."
        echo ""
        echo "Note: The options are executed in the order they are provided."
        echo "      Providing an option twice will execute it twice."
        exit 0
    fi
done

# Otherwise execute commands in order.
for arg in "$@"; do
    if [[ "$arg" == "--start" ]]; then
        fn_start
        ((exit_status+=$?))
    elif [[ "$arg" == "--stop" ]]; then
        fn_stop
    elif [[ "$arg" == "--reset" ]]; then
        fn_reset
        ((exit_status+=$?))
    elif [[ "$arg" == "--read" ]]; then
        fn_read
    elif [[ "$arg" == "--run" ]]; then
        fn_run
    else
        echo -e "${ce}Unknown argument: '${arg}'${e}"
        echo "Use '--help' for more info."
        exit 1
    fi
done
exit ${exit_status}
