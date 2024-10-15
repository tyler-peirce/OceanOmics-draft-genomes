#!/bin/bash
#SBATCH -J 07a_filter-adaptors
#SBATCH --time=00:40:00
#SBATCH --cpus-per-task=6
#SBATCH --partition=work
#SBATCH --mem=15G
#SBATCH --account=pawsey0812
#SBATCH --mail-type=BEGIN,END
#SBATCH --mail-user=
#SBATCH --output=%x-%j.out  #SBATCH --error=%x-%j.err
module load python/3.11.6

python3 --version
python --version

sample=$1
rundir=$2
assembly=$3
fasta=$4
out_dir=$5
action_report="$rundir/$sample/assemblies/genome/NCBI/adaptor/fcs_adaptor_report.txt"

python3 $SING/fcs.py --image=$SING/fcs-gx.sif clean genome -i "$fasta" --action-report "$action_report" --output "$out_dir/$assembly.rmadapt.fasta" --contam-fasta-out "$out_dir/$assembly.adaptor-contam.fasta"

