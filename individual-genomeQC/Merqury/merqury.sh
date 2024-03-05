#!/bin/bash --login
#---------------
#merq.sh.sh : reference-free assembly evaluation based on efficient k-mer set operations
#---------------
#Requested resources:
#SBATCH --account=pawsey0812
#SBATCH --job-name=merq
#SBATCH --partition=work
#SBATCH --ntasks=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=6
#SBATCH --time=02:00:00
#SBATCH --mem=10G
#SBATCH --export=ALL
#SBATCH --output=%x-%j.out
#SBATCH --error=%x-%j.err
#SBATCH --mail-type=BEGIN,END
#SBATCH --mail-user=lauren.huet@uwa.edu.au


SAMPLE=$1
RUNDIR=$2
FASTA=$RUNDIR/$SAMPLE/assemblies/genome/*.v129mh.fna
kmer_dir=$RUNDIR/$SAMPLE/kmers

singularity run $SING/merqury:1.3.sif merqury.sh *.meryl $FASTA $SAMPLE.merqury

wait 


tar -czvf  $kmer_dir/$SAMPLE.meryl.tar.gz $kmer_dir/$SAMPLE.meryl
