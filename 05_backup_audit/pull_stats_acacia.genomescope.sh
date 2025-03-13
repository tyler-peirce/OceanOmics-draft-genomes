#!/bin/bash

mkdir -p acacia_stats
out=acacia_stats
# Genomescope
list=list.genomescope.txt

acacia_location=pawsey0812:oceanomics-genomes/genomes.v2

tsv=$out/genomescope_compiled_results.tsv
echo Sample,Homozygosity,Heterozygosity,GenomeSize,RepeatSize,UniqueSize,ModelFit,ErrorRate | sed 's/,/\t/g' | tee $tsv

while IFS= read -r og; do
command="lsf $acacia_location/$og/kmers/ --include "*-genomescope_summary.txt""

#tree="tree $acacia_location/$og"  # To see if there are actually files
#rclone $tree  # Running the tree command

#echo "command = $command"
#echo rclone $command
prefix=$(rclone $command | head -n 1 | sed 's:/$::')
#echo "prefix = $prefix"

gscope_path=$acacia_location/$og/kmers/$prefix/$prefix-genomescope_summary.txt
read_command="cat $gscope_path"
#echo $read_command
rclone $read_command | sed -E 's/ [ ]+/\t/g' | awk -F '\t' '{print $3;}' | tail -n 8 | awk '{print $1;}' | tr '\n' '\t' | sed 's/\t$/\n/' | sed "s/max/$prefix/" | tee -a $tsv
echo "processed $og"
done < $list


## To get results when they were named differently
while IFS= read -r og; do
command="lsf $acacia_location/$og/assemblies/genome/  --files-only"

tree="tree $acacia_location/$og"  # To see if there are actually files
rclone $tree  # Running the tree command

#echo "command = $command"
#echo rclone $command

prefix=$(rclone $command | head -n 1 | awk -F'.' '{print $1"."$2"."$3}') # gets the prefix from the genome file
echo "prefix = $prefix"

gscope_path=$acacia_location/$og/kmers/$og.genomescope/$og/$og-genomescope_summary.txt
read_command="cat $gscope_path"
echo $read_command
rclone $read_command
rclone $read_command | sed -E 's/ [ ]+/\t/g' | awk -F '\t' '{print $3;}' | tail -n 8 | awk '{print $1;}' | tr '\n' '\t' | sed 's/\t$/\n/' | sed "s/max/$prefix/" | tee -a $tsv
echo "processed $og"
done < $list
