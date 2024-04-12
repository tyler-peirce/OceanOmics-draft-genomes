#!/bin/bash
#SBATCH -J tiara
#SBATCH --time=00:20:00
#SBATCH --cpus-per-task=12
#SBATCH --partition=work
#SBATCH --mem=50G
#SBATCH --account=pawsey0812
#SBATCH --mail-type=END
#SBATCH --export=ALL
#SBATCH --output=%x-%j.out
#SBATCH --error=%x-%j.err
#SBATCH --mail-type=END
#SBATCH --mail-user=lauren.huet@uwa.edu.au
date=$(date +%y%m%d)


sample=$1
rundir=$2
assembly=$3
fasta=$4
out_dir="$rundir/$sample/assemblies/genome/tiara"


 
singularity run $SING/tiara:1.0.3.sif tiara -i $fasta -o $out_dir/$assembly.tiara.txt -m 1000 --tf mit pla pro -t 4 -p 0.65 0.60 --probabilities
