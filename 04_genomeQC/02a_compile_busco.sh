
#!/bin/bash

# Load in the configfile
. ../configfile.txt

mkdir -p $results

cd $rundir

output_file=$results/"${DATE}_BUSCO_compiled_results.tsv"
echo -e "sample\tcomplete\tsingle_copy\tmulti_copy\tfragmented\tmissing\tn_markers\tdomain\tnumber_of_scaffolds\tnumber_of_contigs\ttotal_length\tpercent_gaps\tscaffold_n50\tcontigs_n50" > $output_file



# Find all .tsv files in the current directory and its subdirectories
tsv_files=$(find . -name "*busco.*.short_summary.json.tsv")

###***************** need to edit this to split up the name int sample, tech, seq_date for the sql database*******
# Append the data rows from each .tsv file to the output file
for file in $tsv_files; do
  # Skip the first line (header row) and append the rest to the output file
  tail -n +2 "$file" >> "$output_file"
done
