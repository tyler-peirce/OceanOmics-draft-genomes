#!/bin/bash

# Load in the configfile
. ../configfile.txt


for i in $rundir/*; do
    if [ -d "$i" ]; then
        sample=$(basename "$i")
        assembly=$(basename "$i.ilmn.$DATE")
        rundir=$(dirname "$i") 
        fasta="$rundir/$sample/assemblies/genome/$assembly.v129mh.fa"
        mkdir -p $rundir/$sample/assemblies/genome/NCBI/adaptor
        out_dir="$rundir/$sample/assemblies/genome/NCBI/adaptor"
        sbatch $scripts/03_decontamination/05a_find-adaptors.sh "$sample" "$rundir" "$assembly" "$fasta" "$out_dir"
 
    fi
done 
