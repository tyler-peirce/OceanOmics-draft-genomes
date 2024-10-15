#!/bin/bash
#SBATCH -J 05a_find-adaptors
#SBATCH --time=00:40:00
#SBATCH --cpus-per-task=6
#SBATCH --partition=work
#SBATCH --mem=25G
#SBATCH --account=pawsey0812
#SBATCH --mail-type=BEGIN,END
#SBATCH --mail-user=lauren.huet@uwa.edu.au
#SBATCH --output=%x-%j.out  #SBATCH --error=%x-%j.err



sample=$1
rundir=$2
assembly=$3
fasta=$4
out_dir="$rundir/$sample/assemblies/genome/NCBI/adaptor"

export TINI_SUBREAPER=yes

$SING/run_fcsadaptor.sh --fasta-input "$fasta" --output-dir "$out_dir" --euk --container-engine singularity --image $SING/fcs-adaptor.sif



