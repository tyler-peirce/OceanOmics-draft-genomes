#!/bin/bash

DATE= [date of seq_run)
output_file="depthsizer_results_$DATE.tdt"
echo -e "SeqFile\tDepMethod\tAdjust\tReadBP\tMapAdjust\tSCDepth\tEstGenomeSize" > $output_file

# Find all .tsv files in the current directory and its subdirectories
tdt_files=$(find . -name "*.tdt")

for file in $tdt_files; do
  sed -n '3p' "$file" >> "$output_file"
done
