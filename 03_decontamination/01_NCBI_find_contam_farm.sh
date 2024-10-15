#!/bin/bash

# Load in the configfile
. ../configfile.txt

for i in $rundir/OG851; do
    if [ -d "$i" ]; then
        sample=$(basename "$i")
        assembly=$(basename "$i").ilmn.$DATE
        rundir=$(dirname "$i")
        fasta="$rundir/$sample/assemblies/genome/$assembly.v129mh.fasta"
        #fasta="$rundir/OG00/assemblies/genome/$assembly.v129mh.fasta"
        tax=$(cat "$results/taxon.txt" | grep -w $sample | awk -F'\t' '{print $4}')
        sbatch $scripts/03_decontamination/01a_NCBI_find_contam.sh "$sample" "$rundir" "$assembly" "$fasta" "$tax"
        #echo "$sample $tax"
    fi
done 
