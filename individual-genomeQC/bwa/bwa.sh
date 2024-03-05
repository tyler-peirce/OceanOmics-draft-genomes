#!/bin/bash
#SBATCH --account=pawsey0812
#SBATCH --job-name=bwa
#SBATCH --partition=work
#SBATCH --ntasks=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=12
#SBATCH --time=15:00:00
#SBATCH --mem=12G
#SBATCH --export=ALL
#SBATCH --mail-type=END
#SBATCH --export=ALL
#SBATCH --output=%x-%j.out
#SBATCH --error=%x-%j.err
#SBATCH --mail-type=END
#SBATCH --mail-user=lauren.huet@uwa.edu.au


module load singularity/3.11.4-nompi


sample=$1
rundir=$2
assembly=$3
assembly_name=$4
R1=$5
R2=$6
bam_dir=$7


singularity run $SING/bwa_samtools.sif bwa index $assembly


wait


singularity run $SING/bwa_samtools.sif bwa mem -t 24 $assembly $R1 $R2 | \
singularity run $SING/bwa_samtools.sif samtools view -@ 8 -S -b - | \
singularity run $SING/bwa_samtools.sif samtools sort -@ 8 -o $bam_dir/$sample.sorted.bam -
