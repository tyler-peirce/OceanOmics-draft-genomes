#!/bin/bash --login
#SBATCH --account=pawsey0812
#SBATCH --job-name=aws-raw-backup
#SBATCH --partition=work
#SBATCH --mem=15GB
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --time=24:00:00
#SBATCH --export=NONE

#-----------------

aws s3 cp --recursive [path-to-raw-data] oceanomics/OceanGenomes/illumina-raw/[$RUNID]
