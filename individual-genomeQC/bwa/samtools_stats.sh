#!/bin/bash
#SBATCH --account=pawsey0812
#SBATCH --job-name=samtools-stats
#SBATCH --partition=work
#SBATCH --ntasks=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --time=01:00:00
#SBATCH --mem=5G
#SBATCH --export=ALL
#SBATCH --mail-type=BEGIN,END
#SBATCH --mail-user=lauren.huet@uwa.edu.au


module load singularity/3.11.4-nompi


sample=$1
rundir=$2
bam=$3
bam_dir=$4


singularity run $SING/samtools_1.16.1.sif samtools stats $bam | grep "^SN" | cut -f 2- > $bam_dir/$sample-sn_results.tsv
