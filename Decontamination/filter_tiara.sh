#!/bin/bash
#SBATCH -J tiara_filter
#SBATCH --time=00:20:00
#SBATCH --cpus-per-task=1
#SBATCH --partition=work
#SBATCH --mem=2G
#SBATCH --account=pawsey0812
#SBATCH --mail-type=END
#SBATCH --export=ALL
#SBATCH --output=%x-%j.out
#SBATCH --error=%x-%j.err
#SBATCH --mail-type=END
#SBATCH --mail-user=lauren.huet@uwa.edu.au
 

sample=$1
rundir=$2
assembly=$3
fasta=$4
out_dir="$rundir/$sample/assemblies/genome/tiara"
out_genome="$rundir/$sample/assemblies/genome"
output_file="$rundir/$sample/assemblies/genome/tiara/$assembly.tiara_filter_summary.txt"
tiara_report="$rundir/$sample/assemblies/genome/tiara/$assembly.tiara.txt"
contig_list="$rundir/$sample/assemblies/genome/tiara/$assembly.tiara.contig_removal.txt"
 
#First compile the results of tiara, this script will generate a summary txt file which will show across each category the number of contigs and number of bp to be filtered. 
 
echo -e "Category\tnum_contigs\tbp" > "$output_file"
count=$(grep -w mitochondrion $tiara_report | wc -l)      
bp=$(grep -w mitochondrion "$tiara_report" | awk -F'len=' '{sum += $2} END {print sum}')
echo "Mitochondrion $count $bp" >> $output_file
count1=$(grep -w plastid $tiara_report | wc -l)
bp1=$(grep -w plastid "$tiara_report" | awk -F'len=' '{sum += $2} END {print sum}')
echo "Plastid $count1 $bp1" >> $output_file 
count2=$(grep -w prokarya $tiara_report | wc -l)
bp2=$(grep -w prokarya "$tiara_report" | awk -F'len=' '{sum += $2} END {print sum}')
echo "Prokarya $count2 $bp2" >> $output_file
 
#Next, print a list of the contigs to filter out based off tiara.txt file output, this will be passed to bbmap to filter the contigs 
 
grep -w mitochondrion "$tiara_report" | awk '{print $1}' >> "$contig_list"
grep -w plastid "$tiara_report" | awk '{print $1}' >> "$contig_list"
grep -w prokarya "$tiara_report" | awk '{print $1}' >> "$contig_list"
wait
 
#at the end of this you will have a .fna file which has been filtered from contaminants detected by tiara
 
singularity run $SING/bbmap:39.01.sif filterbyname.sh in="$fasta" out="$out_genome/$assembly.v129mh.fna" names="$contig_list" exclude 
