#!/bin/bash --login
#SBATCH --account=pawsey0812
#SBATCH --job-name=fastqc-backup
#SBATCH --partition=copy
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --time=24:00:00
#SBATCH --export=NONE
#SBATCH --mail-type=BEGIN,END
#SBATCH --mail-user=
#-----------------
#Loading the required modules
#module load rclone/1.63.1

. ../configfile.txt

rclone copy $rundir/ pawsey0812:oceanomics-fastq/ --checksum #--progress
