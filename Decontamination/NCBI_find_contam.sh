#!/bin/bash
#SBATCH -J decontamination
#SBATCH --time=00:30:00
#SBATCH --cpus-per-task=24
#SBATCH --partition=highmem 
#SBATCH --mem=500G
#SBATCH --account=pawsey0812
#SBATCH --mail-type=BEGIN,END
#SBATCH --mail-user=lauren.huet@uwa.edu.au
 
 
# Link the path to the database
GXDB_LOC="/scratch/pawsey0812/lhuet/NCBI"
 
 
# Specify the number of cores (GitHub recommends 48 cores which is approx 24 CPUs)
GX_NUM_CORES=48
 
 
 
sample=$1
rundir=$2
fasta=$3
out_dir="$rundir/$sample/assemblies/genome/NCBI"
 
 
#Run the Python script with appropriate arguments
python3 $SING/fcs.py --image=$SING/fcs-gx.sif screen genome --fasta "$fasta" --out-dir "$out_dir" --gx-db "$GXDB_LOC/gxdb" --tax-id 7898
