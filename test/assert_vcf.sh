#!/bin/bash
# changed grep pattern from '##' to cut out SAMPLE_ID in header
function md5_vcf {
    grep -vE "^#+" "$1" | md5sum | cut -f 1 -d " "
}

received=$(md5_vcf "$1")
expected=$(md5_vcf "$2")

if [ "$received" == "$expected" ]; then
    echo "VCF files are equal"
    exit 0
else
    echo "VCF files are not equal" >&2
    exit 1
fi
