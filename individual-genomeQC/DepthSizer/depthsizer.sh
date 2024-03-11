#!/bin/bash
#SBATCH -J depthsizer
#SBATCH --time=08:00:00
#SBATCH --cpus-per-task=6
#SBATCH --ntasks-per-node=1
#SBATCH --ntasks=1
#SBATCH --mem=180G
#SBATCH --partition=work
#SBATCH --clusters=setonix
#SBATCH --account=pawsey0812
#SBATCH --export=ALL
#SBATCH --output=%x-%j.out
#SBATCH --error=%x-%j.err
#SBATCH --mail-type=END
#SBATCH --mail-user=



SAMPLE=$1
RUNDIR=$2
R1=$3
R2=$4
BAMFILE=$5
BUSCOTSV=$6
FASTA=$7
OUTNAME=$8

singularity run $SING/depthsizer:v1.8.0 python /opt/depthsizer_code/scripts/depthsizer.py -seqin $FASTA -bam $BAMFILE -busco $BUSCOTSV -reads $R1,$R2 -basefile $OUTNAME -forks 40 i=-1 v=0
