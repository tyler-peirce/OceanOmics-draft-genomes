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


for SAMP in $(cat $scripts/00_data_management/$RUN.forcat.prefix.txt); do
    #Remove the trailing letter on the OG numbers
    SAMPLE=$(echo "$SAMP" | sed 's/[A-Z][0-9]*$//')
    
    echo "Running $SAMPLE" | tee -a $RUN.cat.log
    $scripts/00_data_management/04a_wgs-cat.sh $RUN $SAMPLE && echo
    echo "$SAMPLE Complete" | tee -a $RUN.cat.log
done 
