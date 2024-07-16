rundir=
DATE= [this is the date of the sequencing run as appears in the assembly file]
scripts=
for i in $rundir/*; do
if [ -d "$i" ]; then
sample=$(basename "$i")
assembly=$(basename "$i.ilmn.$DATE")
rundir=
fasta="$rundir/$sample/assemblies/genome/$assembly.v129mh.fasta"
sbatch $scripts/filter_NCBI.sh "$sample" "$rundir" "$assembly" "$fasta"
 
fi
done 
