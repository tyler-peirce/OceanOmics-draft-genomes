#!/bin/bash

# Load in the configfile
. ../configfile.txt

mkdir -p $results

####
#Filter report 
####

txt=$results/"$DATE"_NCBI_filter_report.tsv
echo -e "sample\tcategory\tnum_contigs\tbp" > $txt

for contig in $rundir/OG*/assemblies/genome/NCBI/*.$DATE.filter_report.txt; do
    PREFIX=$(basename $contig | awk -F ".filter_report." '{print $1;}')
    
    while read -r CATEGORY NUM_CONTIGS BP; do
        echo -e "$PREFIX\t$CATEGORY\t$NUM_CONTIGS\t$BP" >> $txt
    done < $contig


done
column -t $txt

####
#Contig count compile
####

txt=$results/"$DATE"_NCBI_contig_count_500bp.tsv
echo sample,num_contigs | sed 's/,/\t/g' | tee $txt

for contig in $rundir/OG*/assemblies/genome/NCBI/*.$DATE.contig_count_500bp.txt; do

PREFIX=$(basename $contig | awk -F ".contig_count." '{print $1;}')
NUM_CONTIGS=$(grep "Number of contigs less than 500bp:" $contig | awk -F ": " '{print $2}')
echo -e "$PREFIX\t$NUM_CONTIGS" >> $txt

done
column -t $txt
