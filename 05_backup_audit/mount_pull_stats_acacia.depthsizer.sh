#!/bin/bash

mkdir -p acacia_stats
out=acacia_stats
acacia_location=pawsey0812:oceanomics-genomes/genomes.v2

mkdir -p mounted_acacia
mounted_acacia=mounted_acacia
# You need to mount acacia to your scratch before the running the script. 
# And then you need to unmount it after you're finished by running 'umount mounted_acacia'
#rclone mount pawsey0812:oceanomics-genomes/genomes.v2 mounted_acacia/ --daemon


output_file=$out/all_depthsizer_results.tsv
echo -e "SeqFile\tDepMethod\tAdjust\tReadBP\tMapAdjust\tSCDepth\tEstGenomeSize" > $output_file

# Find all .tsv files in the current directory and its subdirectories
tdt_files=$(find $mounted_acacia/. -name "*.tdt")

for file in $tdt_files; do
  sed -n '3p' "$file" >> "$output_file"
done
