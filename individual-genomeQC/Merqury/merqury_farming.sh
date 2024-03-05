#!/bin/bash
####
##Note* Run Merqury from the location of where the meryl db is located, generated during the assembly nextflow. 
###
RUNDIR=
DATE=
SCRIPTS=
for i in "$RUNDIR"/OG*; do
    if [ -d "$i" ]; then  # Check if the item in $RUNDIR is a directory
        SAMPLE=$(basename "$i")
        kmers_dir="$RUNDIR/$SAMPLE/kmers"  #(OR path to where your db is located!)
        RUNDIR=
        cd $kmers_dir
        sbatch $SCRIPTS/merqury.sh "$SAMPLE" "$RUNDIR"
    fi
done
