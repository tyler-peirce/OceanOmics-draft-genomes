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





RUN=NEXT_221115_LP
DIR=/scratch/pawsey0812/lhuet/NEXT_221115_LP
SCRIPTS=/scratch/pawsey0812/lhuet/scripts


for SAMPLE in $(cat $DIR/$RUN.forcat.prefix.txt); do
echo "Running $SAMPLE" | tee -a $RUN.cat.log
$SCRIPTS/wgs-cat.sh $DIR $RUN $SAMPLE && echo
"$SAMPLE Complete" | tee -a $RUN.cat.log
done 
