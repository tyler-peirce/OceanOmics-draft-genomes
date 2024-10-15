#!/bin/bash

# Load in the configfile
. ../configfile.txt


for i in $rundir/OG*; do
    if [ -d "$i" ]; then
        sample=$(basename "$i")
        assembly=$(basename "$i.ilmn.$DATE")
        rundir=$(dirname "$i") 
        fasta="$rundir/$sample/assemblies/genome/$assembly.v129mh.fa"
        out_dir="$rundir/$sample/assemblies/genome"

        sbatch $scripts/03_decontamination/07a_filter-adaptors.sh "$sample" "$rundir" "$assembly" "$fasta" "$out_dir"

    fi
done 
