#!/bin/bash
function remove_sample_id_and_md5 {
    cat $1 | sed 's/extracted_mt_reads[A-Za-z0-9\_]*/extracted_mt_reads/g' | md5sum | cut -f 1 -d ' '
}

received=$(remove_sample_id_and_md5 $1)
expected=$(remove_sample_id_and_md5 $2)

if [ "$received" == "$expected" ]; then
    echo "csv files are equal"
    exit 0
else
    echo "csv files are not equal" >&2
    exit 1
fi