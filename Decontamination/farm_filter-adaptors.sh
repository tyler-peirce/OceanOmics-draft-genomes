rundir= [ Run Direcotry ] 
DATE= [ date of sequencing run ]
scripts=/scratch/pawsey0812/lhuet/OceanOmics-draft-genomes/Decontamination
for i in $rundir/*; do
if [ -d "$i" ]; then
sample=$(basename "$i")
assembly=$(basename "$i.ilmn.$DATE")
rundir= [ Run Direcotry ]  
fasta="$rundir/$sample/assemblies/genome/$assembly.v129mh.fa"
out_dir="$rundir/$sample/assemblies/genome"

sbatch $scripts/filter-adaptors.sh "$sample" "$rundir" "$assembly" "$fasta" "$out_dir"

fi
done 
