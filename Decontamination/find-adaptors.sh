#!/bin/bash
#SBATCH -J find-adaptors
#SBATCH --time=00:40:00
#SBATCH --cpus-per-task=6
#SBATCH --partition=work
#SBATCH --mem=10G
#SBATCH --account=pawsey0812
#SBATCH --mail-type=BEGIN,END
#SBATCH --mail-user=lauren.huet@uwa.edu.au



sample=$1
rundir=$2
assembly=$3
fasta=$4
out_dir="$rundir/$sample/assemblies/genome/NCBI/adaptor"

export TINI_SUBREAPER=yes

$SING/run_fcsadaptor.sh --fasta-input "$fasta" --output-dir "$out_dir" --euk --container-engine singularity --image $SING/fcs-adaptor.sif



