#!/bin/bash --login
#SBATCH --account=pawsey0812
#SBATCH --job-name=decontamination
#SBATCH --partition=work
#SBATCH --cpus-per-task=1
#SBATCH --ntasks-per-node=1
#SBATCH --time=24:00:00
#SBATCH --mem=12G

#SBATCH --export=NONE

#-----------------

. ../configfile.txt

# Run these modules the first time you run the script, then comment out
#module load nextflow/
#module unload gcc
#module swap pawseyenv/2024.05 pawseyenv/2023.08
#module load gcc

#Loading the required modules
module load singularity/3.11.4-slurm

# Setting the .nextflow to be stored on your scratch instead of in software
unset SBATCH_EXPORT
export NXF_HOME=$MYSCRATCH/.nextflow

# Running the nextflow
nextflow run decontamination.nf -c nextflow.config -profile setonix -resume -disable-jobs-cancellation -with-report decontamination.html
