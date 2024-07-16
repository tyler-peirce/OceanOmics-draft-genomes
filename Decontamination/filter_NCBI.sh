#!/bin/bash
#SBATCH -J decontamination
#SBATCH --time=00:20:00
#SBATCH --cpus-per-task=1
#SBATCH --partition=work
#SBATCH --mem=2G
#SBATCH --account=pawsey0812
#SBATCH --mail-type=BEGIN,END
#SBATCH --mail-user=lauren.huet@uwa.edu.au



sample=$1
rundir=$2
assembly=$3
fasta=$4
out_dir="$rundir/$sample/assemblies/genome/NCBI"
action_report="$rundir/$sample/assemblies/genome/NCBI/$assembly.v129mh.7898.fcs_gx_report.txt"
output_file="$rundir/$sample/assemblies/genome/NCBI/$assembly.filter_report.txt"
review_report="$rundir/$sample/assemblies/genome/NCBI/$assembly.review_scaffolds_1kb.txt"
filter_in="$rundir/$sample/assemblies/genome/NCBI"
contig_count="$rundir/$sample/assemblies/genome/NCBI/$assembly.contig_count_500bp.txt"
final_out="$rundir/$sample/assemblies/genome"



#remove the exclude and trim seqeunces 
python3 $SING/fcs.py --image=$SING/fcs-gx.sif clean genome -i $fasta --action-report "$action_report" --output "$out_dir/$assembly.v129mh.rc.fasta" --contam-fasta-out "$out_dir/$sample.contam.fasta"


wait 


# count the number of contigs and the number of base pairs being removed across EXCLUDE and TRIM 

#first remove output file incase of multiple runs. 
###
rm $output_file
####
count=$(grep -w EXCLUDE "$action_report" | cut -f 1 | sort -u | wc -l)
bp=$(grep -w EXCLUDE "$action_report" | awk '{sum+=$3-$2+1}END{print sum}')
echo "EXCLUDE $count $bp" >> "$output_file"


count=$(grep -w TRIM "$action_report" | cut -f 1 | sort -u | wc -l)
bp=$(grep -w TRIM "$action_report" | awk '{sum+=$3-$2+1}END{print sum}')
echo "TRIM $count $bp" >> "$output_file"


# count the number of contigs 1000bp or less and number of total bp to be filtered
count=$(grep -w REVIEW "$action_report" | awk '$4 <= 1000'| cut -f 1 | sort -u | wc -l)
bp=$(grep -w REVIEW "$action_report" | awk '$4 <= 1000'| awk '{sum+=$3-$2+1}END{print sum}')
echo "REVIEW $count $bp" >> "$output_file"


#generate a txt file with the name of the contigs that are in review that are less that 1000bp.
grep -w REVIEW "$action_report" | awk '$4 <= 1000' | awk '{print $1}' > "$review_report"


# remove these contigs 
singularity run $SING/bbmap:39.01.sif filterbyname.sh in="$out_dir/$assembly.v129mh.rc.fasta" out="$out_dir/$assembly.v129mh.rf.fa" names="$review_report" exclude 


# Wait for the first bbmap script to complete before moving on
wait


grep -v '^>' $out_dir/$assembly.v129mh.rf.fa | awk 'length($0) < 500 {count++} END {print "Number of contigs less than 500bp:", count}' > "$contig_count"


#remove the contigs that are less than 500bp from the assembly 
singularity run $SING/bbmap:39.01.sif reformat.sh in="$filter_in/$assembly.v129mh.rf.fa" out="$final_out/$assembly.v129mh.fa" minlength=500
