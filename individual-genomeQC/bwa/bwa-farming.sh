rundir=
scripts=
for i in $rundir/*; do
if [ -d "$i" ]; then
sample=$(basename "$i")
DATE=230419
sample_name=$(basename "$i.ilmn.$DATE")
assembly="$rundir/$sample/assemblies/genome/$sample_name.v129mh.fna"
R1="$rundir/$sample/fastp/$sample_name.R1.fastq.gz"
R2="$rundir/$sample/fastp/$sample_name.R2.fastq.gz"
rundir=
bam_dir=$rundir/$sample/assemblies/genome/bam
mkdir -p "$bam_dir"
cd $bam_dir
sbatch $scripts/bwa.sh "$sample" "$rundir" "$sample_name" "$assembly" "$bam_dir" "$R1" "$R2"
 
fi
done
