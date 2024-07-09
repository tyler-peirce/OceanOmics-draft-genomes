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





#!/bin/bash
#SBATCH -J pool_rename
#SBATCH --time=24:00:00
#SBATCH --ntasks=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=64G
#SBATCH --partition=work
#SBATCH --clusters=setonix
#SBATCH --account=pawsey0812





RUN=NOVA_231024_AD
DIR=/scratch/pawsey0812/lhuet/download
SCRIPTS=/scratch/pawsey0812/lhuet/OceanOmics-draft-genomes/data_management


##############
# Ensure you have removed any trailing letters off the OG numbers in the $RUN.forcat.prefix.txt file before runing this script
#############
for SAMPLE in $(cat $DIR/$RUN.forcat.prefix.txt); do
echo "Running $SAMPLE" | tee -a $RUN.cat.log
$SCRIPTS/wgs-cat.sh $RUN $SAMPLE $DIR  && echo
"$SAMPLE Complete" | tee -a $RUN.cat.log
done 
