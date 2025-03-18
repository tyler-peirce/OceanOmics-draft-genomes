#!/bin/bash
mkdir -p acacia_stats
out=acacia_stats
acacia_location=pawsey0812:oceanomics-genomes/genomes.v2

mkdir -p mounted_acacia
mounted_acacia=mounted_acacia
# You need to mount acacia to your scratch before the running the script. 
# And then you need to unmount it after you're finished by running 'umount mounted_acacia'
#rclone mount pawsey0812:oceanomics-genomes/genomes.v2 mounted_acacia/ --daemon

# Define the output file and create the column headings
TSV=$out/all_genomescope_compiled_results.tsv
echo Sample,Homozygosity,Heterozygosity,GenomeSize,RepeatSize,UniqueSize,ModelFit,ErrorRate | sed 's/,/\t/g' | tee $TSV


for GSCOPE in $mounted_acacia/OG*/kmers/*/*-genomescope_summary.txt; do
PREFIX=$(basename $GSCOPE | awk -F "-genomescope" '{print $1;}')
sed -E 's/ [ ]+/\t/g' $GSCOPE | awk -F '\t' '{print $3;}' | tail -n 8 | awk '{print $1;}' | tr '\n' '\t' | sed 's/\t$/\n/' | sed "s/max/$PREFIX/" | tee -a $TSV
done
column -t $TSV
