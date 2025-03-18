#!/bin/bash

mkdir -p acacia_stats
out=acacia_stats
acacia_location=pawsey0812:oceanomics-genomes/genomes.v2

mkdir -p mounted_acacia
mounted_acacia=mounted_acacia
# You need to mount acacia to your scratch before the running the script. 
# And then you need to unmount it after you're finished by running 'umount mounted_acacia'
#rclone mount pawsey0812:oceanomics-genomes/genomes.v2 mounted_acacia/ --daemon

txt=$out/all_NCBI_filter_report.tsv
echo -e "sample\tcategory\tnum_contigs\tbp" > $txt

for contig in $mounted_acacia/OG*/assemblies/genome/NCBI/*.filter_report.txt; do
    PREFIX=$(basename $contig | awk -F ".filter_report." '{print $1;}')
    
    while read -r CATEGORY NUM_CONTIGS BP; do
        echo -e "$PREFIX\t$CATEGORY\t$NUM_CONTIGS\t$BP" >> $txt
    done < $contig


done
column -t $txt

####
#Contig count compile
####

txt=$out/all_NCBI_contig_count_500bp.tsv
echo sample,num_contigs | sed 's/,/\t/g' | tee $txt

for contig in $mounted_acacia/OG*/assemblies/genome/NCBI/*.contig_count_500bp.txt; do

PREFIX=$(basename $contig | awk -F ".contig_count." '{print $1;}')
NUM_CONTIGS=$(grep "Number of contigs less than 500bp:" $contig | awk -F ": " '{print $2}')
echo -e "$PREFIX\t$NUM_CONTIGS" >> $txt

done
column -t $txt
