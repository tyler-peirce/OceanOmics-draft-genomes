#!/bin/bash

# Load in the configfile
. ../configfile.txt

####
#Filter report 
####
list=list.tiara.txt
mkdir -p acacia_stats
out=acacia_stats

acacia_location=pawsey0812:oceanomics-genomes/genomes.v2

txt=$out/tiara_filter_report.tsv
echo -e "sample\tcategory\tnum_contigs\tbp" > $txt

while IFS= read -r og; do
    command="lsf $acacia_location/$og/assemblies/genome/tiara/ --include "*tiara_filter_summary.txt""
    rclone $command
    file=$(rclone $command)
    echo "file = $file"
    PREFIX=$(echo $file | awk -F'.' '{print $(NF-3) "." $(NF-2)}')
    echo "prefix = $PREFIX"
    
    command2="cat $acacia_location/$og/assemblies/genome/tiara/ --include "*tiara_filter_summary.txt""
    rclone $command2 | tail -n +2 | while read -r CATEGORY NUM_CONTIGS BP; do
        echo -e "$og.$PREFIX\t$CATEGORY\t$NUM_CONTIGS\t$BP" >> $txt
    done


done < $list
column -t $txt
