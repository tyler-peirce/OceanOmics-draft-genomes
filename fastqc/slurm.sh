#!/bin/bash --login
#SBATCH --account=
#SBATCH --job-name=
#SBATCH --partition=work
#SBATCH --cpus-per-task=1
#SBATCH --ntasks-per-node=1
#SBATCH --time=24:00:00
#SBATCH --mem=12G

#SBATCH --export=NONE

#-----------------
#Loading the required modules

module load nextflow/23.10.0

unset SBATCH_EXPORT

nextflow run fastqc.nf -c nextflow.config -profile setonix -resume -disable-jobs-cancellation -with-report [RUN].html
