#!/bin/bash --login

#SBATCH --account=pawsey0812
#SBATCH --job-name=final-genome-upload
#SBATCH --partition=long
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --time=60:00:00
#SBATCH --export=NONE
#SBATCH --mail-type=BEGIN,END
#SBATCH --mail-user=
#-----------------
#Loading the required modules



rclone move [path-to-run-directory] pawsey0812:oceanomics-genomes/genomes.v2/  --checksum -P
