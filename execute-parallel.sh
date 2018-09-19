#!/bin/bash

## Usage:
## ./execute-parallel.sh {MAX_CHILDREN} {MAX_PROCESSES} {COMMAND}

if [ "$#" -le 2 ]; then
    echo "Illegal number of parameters"
    exit -1
fi

if [ "$1" -le "0" ] || [ "$1" -gt "100" ]; then
    echo "Illegal number of children"
    exit -1
fi

if [ "$1" -le "0" ] || [ "$1" -gt "100000" ]; then
    echo "Illegal amount of processes"
    exit -1
fi

max_children=$1
max_processes=$2
command=${@:3}
my_pid=$$

function parallel {
    local time1=$(date +"%H:%M:%S")
    local time2=""
    local last_pid=""

    local children=$(ps -eo ppid | grep -w ${my_pid} | wc -l)
    children=$((children-1))

    echo -e "$children of $max_children processes running...\n"

    while [[ ${children} -ge ${max_children} ]]; do
        echo -e "wait...\n"

        pstree -a -l -p -t ${my_pid} 2>/dev/null && echo -e -n "\n"

        wait -n 2>/dev/null || sleep 1

        children=$(ps -eo ppid | grep -w $my_pid | wc -l)
        children=$((children-1))
    done

    echo "starting $@ ($time1)..."
    "$@" && time2=$(date +"%H:%M:%S") && echo -e "finishing $@ ($time1 -- $time2)...\n" &

    last_pid=$!
    echo "started with pid: $last_pid"

    echo -e -n "\n"
}

echo "my pid: $my_pid"

processes=0
while [ "${processes}" -le "${max_processes}" ]; do
    if ! [ -x "$(command -v ionice)" ]; then
        printf -v exec_command "${command}"
    else
        printf -v exec_command "ionice -c3 ${command}"
    fi

    parallel ${exec_command}
    processes=$(expr ${processes} + 1)

    echo -e -n "\n"
done

wait
