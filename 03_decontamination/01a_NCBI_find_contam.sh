#!/bin/bash
#SBATCH -J 01a_NCBI_find_contam.sh
#SBATCH --time=04:00:00
#SBATCH --cpus-per-task=24
#SBATCH --partition=highmem 
#SBATCH --mem=800G
#SBATCH --account=pawsey0812
#SBATCH --mail-type=BEGIN,END
#SBATCH --output=%x-%j.out  #SBATCH --error=%x-%j.err
 
module load python/3.11.6

python3 --version
python --version
singularity --version

# Link the path to the database
GXDB_LOC="/scratch/references/Foreign_Contamination_Screening"
#GX_NUM_CORES=48  
echo "Contents of /tmp/:"
ls /tmp/

rm -r /tmp/gxdb/
echo ‘copying’
rclone copy "$GXDB_LOC/gxdb/all.gxi" /tmp/gxdb/ --progress
rclone copy "$GXDB_LOC/gxdb/all.gxs" /tmp/gxdb/ --progress
rclone copy "$GXDB_LOC/gxdb/all.meta.jsonl" /tmp/gxdb/ --progress
rclone copy "$GXDB_LOC/gxdb/all.blast_div.tsv.gz" /tmp/gxdb/ --progress
rclone copy "$GXDB_LOC/gxdb/all.taxa.tsv" /tmp/gxdb/ --progress
echo ‘done copying’ 
 
sample=$1
rundir=$2
assembly=$3
fasta=$4
tax=$5
out_dir="$rundir/$sample/assemblies/genome/NCBI"

echo "sample = $sample"
echo "rundir = $rundir"
echo "assembly = $assembly"
echo "fasta = $fasta"
echo "out_dir = $out_dir" 
echo "tax = $tax"

#Run the Python script with appropriate arguments
python3 $SING/fcs.py --image=$SING/fcs-gx.sif screen genome --fasta "$fasta" --out-dir "$out_dir" --gx-db "/tmp/gxdb" --tax-id "$tax" --debug

#python $SING/fcs.py --env-file env.txt --image=$SING/fcs-gx.sif screen genome --fasta "/scratch/pawsey0812/tpeirce/DRAFTGENOME/OUTPUT/OG00/assemblies/genome/OG00.ilmn.240716.v129mh.fasta" --out-dir "/scratch/pawsey0812/tpeirce/DRAFTGENOME/OUTPUT/OG00/assemblies/genome/NCBI" --gx-db "/scratch/pawsey0812/lhuet/NCBI/gxdb" --tax-id "8245" --debug
