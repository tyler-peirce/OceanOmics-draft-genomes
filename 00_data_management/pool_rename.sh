#!/bin/bash
#SBATCH -J pool_rename
#SBATCH --time=12:00:00
#SBATCH --ntasks=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=64G
#SBATCH --partition=work
#SBATCH --clusters=setonix
#SBATCH --account=pawsey0812

. ../configfile.txt


for SAMP in $(cat $scripts/data_management/$RUN.forcat.prefix.txt); do
    #Remove the trailing letter on the OG numbers
    SAMPLE=$(echo $SAMP | sed 's/.$//')
    
    echo "Running $SAMPLE" | tee -a $RUN.cat.log
    $scripts/data_management/wgs-cat.sh $RUN $SAMPLE && echo
    "$SAMPLE Complete" | tee -a $RUN.cat.log
done 
