#!/bin/bash

# Load in the configfile
. ../configfile.txt

for i in $rundir/*; do
    if [ -d "$i" ]; then
        sample=$(basename "$i")
        assembly=$(basename "$i.ilmn.$DATE")
        fasta=$rundir/$sample/assemblies/genome/$assembly.rmadapt.fasta
        sbatch $scripts/03_decontamination/09a_tiara_find_contam.sh "$sample" "$rundir" "$assembly" "$fasta"
 
    fi
done 
