#!/bin/bash
. ../configfile.txt


# Find all .tsv files in the specified directories and perform the replacement
for file in $rundir/OG*/fastp/*.html; do
    dir=$(dirname "$file")
    name=$(basename "$file")
    newname=$(echo $name | awk -F '.' '{print $1"."$2".240716."$4"."$5}')
    echo "$file"
    echo "$dir/$newname"

    mv "$file" "$dir/$newname"
done


for file in $rundir/OG*/fastp/*fastq.gz; do
    dir=$(dirname "$file")
    name=$(basename "$file")
    newname=$(echo $name | awk -F '.' '{print $1"."$2".240716."$4"."$5"."$6}')
    echo "$file"
    echo "$dir/$newname"

    mv "$file" "$dir/$newname"
done