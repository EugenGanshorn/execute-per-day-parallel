#!/bin/bash

## Usage:
## ./execute-per-param-parallel.sh {MAX_CHILDREN} {COMMAND} {PARAMS}

if [ "$#" -le 4 ]; then
    echo "Illegal number of parameters"
    exit -1
fi

if [ "$1" -le "0" ] || [ "$1" -gt "100" ]; then
    echo "Illegal number of children"
    exit -1
fi

max_children=$1
command=$2 || exit -1
params=${@:3}
my_pid=$$

function parallel {
    local param=""
    local last_pid=""

    local children=$(ps -eo ppid | grep -w $my_pid | wc -l)
    children=$((children-1))

    echo -e "$children of $max_children processes running...\n"

    while [[ $children -ge $max_children ]]; do
        echo -e "wait...\n"

        pstree -a -l -p -t $my_pid 2>/dev/null && echo -e -n "\n"

        wait -n 2>/dev/null || sleep 1

        children=$(ps -eo ppid | grep -w $my_pid | wc -l)
        children=$((children-1))
    done

    echo "starting $@ ..."
    "$@" && echo -e "finishing $@ ...\n" &

    last_pid=$!
    echo "started with pid: $last_pid"

    echo -e -n "\n"
}

echo "my pid: $my_pid"

for param in $params; do
    printf -v exec_command "$command" "$param"
    parallel $exec_command

    echo -e -n "\n"
done

wait
