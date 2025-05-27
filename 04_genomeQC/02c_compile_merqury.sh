#!/bin/bash

# Load in the configfile
. ../configfile.txt

mkdir -p $results

### COMPILE completeness stats 

output_file=$results/"$DATE"_merqury.completeness.stats.tsv
echo -e "sample\tk_mer_set\tsolid_k_mers\ttotal_k_mers\tcompleteness" > $output_file
#find all .merqury.completeness.stats files 
completeness_files=$(find $rundir/. -name "*.merqury.completeness.stats")

        
for i in $completeness_files; do
    cat "$i" >> "$output_file"
  done
 



### COMPILE QV STATS 

output_file=$results/"$DATE"_merqury.qv.stats.tsv
echo -e "sample\tunique_k_mers_assembly\tk_mers_total\tqv\terror" > $output_file
#find all .merqury.completeness.stats files 
        completeness_files=$(find $rundir/. -name "*.merqury.qv")
        

for i in $completeness_files; do
     cat "$i" >> "$output_file"
done
