#!/bin/bash
. ../configfile.txt
. ~/.bashrc
#this script is to pull the fastp files if pawsey has deleted them

list=$(ls $rundir)
echo $list
for og in $list; do
    echo "og = $og"
   rclone copy pawsey0812:oceanomics-fastq/$og /scratch/pawsey0812/tpeirce/DRAFTGENOME/OUTPUT/$og
done
