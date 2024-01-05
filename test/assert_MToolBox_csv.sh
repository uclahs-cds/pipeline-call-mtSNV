#!/bin/bash
function trim_and_md5 {
    cat $1 | cut -f 2 -d ',' | md5sum | cut -f 1 -d ' '
}

received=$(trim_and_md5 $1)
expected=$(trim_and_md5 $2)

if [ "$received" == "$expected" ]; then
    echo "csv files are equal"
    exit 0
else
    echo "csv files are not equal" >&2
    exit 1
fi