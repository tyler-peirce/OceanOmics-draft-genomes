
#!/bin/bash
mkdir -p acacia_stats
out=acacia_stats
acacia_location=pawsey0812:oceanomics-genomes/genomes.v2

mkdir -p mounted_acacia
mounted_acacia=mounted_acacia
# You need to mount acacia to your scratch before the running the script. 
# And then you need to unmount it after you're finished by running 'umount mounted_acacia'
#rclone mount pawsey0812:oceanomics-genomes/genomes.v2 mounted_acacia/ --daemon

output_file=$out/all_BUSCO_compiled_results.tsv
echo -e "sample\tComplete\tSingle_copy\tMulti_copy\tFragmented\tMissing\tn_markers\tdomain\tNumber_of_scaffolds\tNumber_of_contigs\tTotal_length\tPercent_gaps\tScaffold_N50\tContigs_N50" > $output_file



# Find all .tsv files in the current directory and its subdirectories
tsv_files=$(find $mounted_acacia/. -name "*busco.*.short_summary.json.tsv")

###***************** need to edit this to split up the name int sample, tech, seq_date for the sql database*******
# Append the data rows from each .tsv file to the output file
for file in $tsv_files; do
  # Skip the first line (header row) and append the rest to the output file
  tail -n +2 "$file" >> "$output_file"
done
