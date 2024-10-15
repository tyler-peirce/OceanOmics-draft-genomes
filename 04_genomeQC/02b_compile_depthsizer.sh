#!/bin/bash

# Load in the configfile
. ../configfile.txt

cd $rundir

output_file=$results/"$DATE"_depthsizer_results.tsv
echo -e "SeqFile\tDepMethod\tAdjust\tReadBP\tMapAdjust\tSCDepth\tEstGenomeSize" > $output_file

# Find all .tsv files in the current directory and its subdirectories
tdt_files=$(find . -name "*.tdt")

for file in $tdt_files; do
  sed -n '3p' "$file" >> "$output_file"
done
