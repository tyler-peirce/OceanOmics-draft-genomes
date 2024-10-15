#!/bin/bash

# Load in the configfile
. ../configfile.txt

for i in $rundir/OG32; do
    if [ -d "$i" ]; then
        sample=$(basename "$i")
        assembly=$(basename "$i.ilmn.$DATE")
        rundir=$(dirname "$i") 
        fasta="$rundir/$sample/assemblies/genome/$assembly.v129mh.fasta"
        tax=$(cat "$results/taxon.txt" | grep -w $sample | awk -F'\t' '{print $4}')
        sbatch $scripts/03_decontamination/03a_filter_NCBI.sh "$sample" "$rundir" "$assembly" "$fasta" "$tax"
 
    fi
done 
