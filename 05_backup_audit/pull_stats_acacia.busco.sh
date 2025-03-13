
#!/bin/bash

list=list.busco.txt
mkdir -p acacia_stats
out=acacia_stats

acacia_location=pawsey0812:oceanomics-genomes/genomes.v2

output_file=$out/"BUSCO_compiled_results.tsv"
echo -e "sample\tComplete\tSingle_copy\tMulti_copy\tFragmented\tMissing\tn_markers\tdomain\tNumber_of_scaffolds\tNumber_of_contigs\tTotal_length\tPercent_gaps\tScaffold_N50\tContigs_N50" > $output_file

while IFS= read -r og; do
  path=$acacia_location/$og/assemblies/genome/
  command="lsf $path --include "busco*/*busco.*.short_summary.json.tsv""
  echo "command = $command"
  rclone $command | while IFR= read -r dir; do
    echo "dir = $dir"
    command2="lsf ${path}${dir} --include "*busco.*.short_summary.json.tsv" --files-only"
    echo "command2 = $command2"
    file=$(rclone $command2)
    echo "file = $file"
    command3="cat ${path}${dir}$file"
    rclone $command3 | tail -n +2 | awk -v prefix="$og" 'BEGIN{OFS="\t"} {
    match($1, /\.ilmn\.[0-9]{6}/);
    if (RSTART) $1 = prefix substr($1, RSTART, RLENGTH); 
    print
    }' >> "$output_file"
  done
done < $list
