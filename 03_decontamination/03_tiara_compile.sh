#!/bin/bash

# Load in the configfile
. ../configfile.txt

mkdir -p $results

####
#Filter report 
####

txt=$results/"$DATE"_tiara_filter_report.tsv
echo -e "sample\tcategory\tnum_contigs\tbp" > $txt


for contig in $rundir/OG*/assemblies/genome/tiara/*.$DATE.tiara_filter_summary.txt; do
    PREFIX=$(basename $contig | awk -F ".tiara_filter_summary." '{print $1;}')
    
    tail -n +2 "$contig" | while read -r CATEGORY NUM_CONTIGS BP; do
        echo -e "$PREFIX\t$CATEGORY\t$NUM_CONTIGS\t$BP" >> $txt
    done 


done
column -t $txt
