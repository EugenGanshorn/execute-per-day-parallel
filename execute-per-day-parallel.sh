#!/bin/bash

## Usage:
## ./execute-per-day-parallel.sh {MAX_CHILDREN} {START_DATE} {END_DATE} {COMMAND}

if [ "$#" -le 4 ]; then
    echo "Illegal number of parameters"
    exit -1
fi

if [ "$1" -le "0" ] || [ "$1" -gt "100" ]; then
    echo "Illegal number of children"
    exit -1
fi

max_children=$1
start_date=$(date -I -d "$2") || exit -1
end_date=$(date -I -d "$3") || exit -1
command=${@:4}
my_pid=$$

if [ "$(date -d "$start_date" +%Y%m%d)" -ge "$(date -d "$end_date" +%Y%m%d)" ]; then
    echo "end date is before start date"
    exit -1
fi

function parallel {
    local time1=$(date +"%H:%M:%S")
    local time2=""
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

    echo "starting $@ ($time1)..."
    "$@" && time2=$(date +"%H:%M:%S") && echo -e "finishing $@ ($time1 -- $time2)...\n" &

    last_pid=$!
    echo "started with pid: $last_pid"

    echo -e -n "\n"
}

echo "my pid: $my_pid"

while [ "$(date -d "$start_date" +%Y%m%d)" -lt "$(date -d "$end_date" +%Y%m%d)" ]; do
    printf -v exec_command "$command" "$start_date" "$(date -I -d "$start_date + 1 day")"
    parallel $exec_command
    start_date=$(date -I -d "$start_date + 1 day")

    echo -e -n "\n"
done

wait
