#!/bin/bash

# Load in the configfile
. ../configfile.txt

mkdir -p $results

# Define the output file and create the column headings
TSV=$results/"$DATE"_genomescope_compiled_results.tsv
echo Sample,Homozygosity,Heterozygosity,GenomeSize,RepeatSize,UniqueSize,ModelFit,ErrorRate | sed 's/,/\t/g' | tee $TSV


for GSCOPE in $rundir/OG*/kmers/*/*genomescope_summary.txt; do
PREFIX=$(basename $GSCOPE | awk -F "-genomescope" '{print $1;}')
sed -E 's/ [ ]+/\t/g' $GSCOPE | awk -F '\t' '{print $3;}' | tail -n 8 | awk '{print $1;}' | tr '\n' '\t' | sed 's/\t$/\n/' | sed "s/max/$PREFIX/" | tee -a $TSV
done
column -t $TSV
