####
#Filter report 
####
DATE=
txt="$DATE.tirara_filter_report.txt"
echo -e "Sample\tCategory\tnum_contigs\tbp" > $txt


for contig in $OG*/assemblies/genome/tiara/*.$DATE.tiara_filter_summary.txt; do
    PREFIX=$(basename $contig | awk -F ".tiara_filter_summary." '{print $1;}')
    
    while read -r CATEGORY NUM_CONTIGS BP; do
        echo -e "$PREFIX\t$CATEGORY\t$NUM_CONTIGS\t$BP" >> $txt
    done < $contig


done
column -t $txt
