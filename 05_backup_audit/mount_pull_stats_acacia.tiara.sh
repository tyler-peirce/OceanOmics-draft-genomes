#!/bin/bash

mkdir -p acacia_stats
out=acacia_stats
acacia_location=pawsey0812:oceanomics-genomes/genomes.v2

mkdir -p mounted_acacia
mounted_acacia=mounted_acacia
# You need to mount acacia to your scratch before the running the script. 
# And then you need to unmount it after you're finished by running 'umount mounted_acacia'
#rclone mount pawsey0812:oceanomics-genomes/genomes.v2 mounted_acacia/ --daemon

txt=$out/all_tiara_filter_report.tsv
echo -e "sample\tcategory\tnum_contigs\tbp" > $txt


for contig in $mounted_acacia/OG*/assemblies/genome/tiara/*.tiara_filter_summary.txt; do
    PREFIX=$(basename $contig | awk -F ".tiara_filter_summary." '{print $1;}')
    
    tail -n +2 "$contig" | while read -r CATEGORY NUM_CONTIGS BP; do
        echo -e "$PREFIX\t$CATEGORY\t$NUM_CONTIGS\t$BP" >> $txt
    done 


done
column -t $txt
