#!/bin/bash
## This script compiles the results of fastp from the rscript for multiple samples of a given run. 

# Load in the configfile
. ../configfile.txt

mkdir -p $results

# Define the output file and create the column headings
TSV=$results/"$DATE"_fastp_compiled_results.tsv
echo Sample,run,passed_filter_reads,low_quality_reads,too_many_N_reads,too_short_reads,too_long_reads,raw.total_reads,raw.total_bases,raw.q20_bases,raw.q30_bases,raw.q20_rate,raw.q30_rate,raw.read1_mean_length,raw.read2_mean_length,raw.gc_content,total_reads,total_bases,q20_bases,q30_bases,q20_rate,q30_rate,read1_mean_length,read2_mean_length,gc_content | sed 's/,/\t/g' | tee $TSV


# Append the data rows from each .tsv file to the output file
for file in $rundir/OG*/fastp/*.tsv; do
  # Skip the first line (header row) and append the rest to the output file
  tail -n +2 "$file" >> "$TSV"
done


echo "Compilation completed. Results are stored in '$TSV'."
