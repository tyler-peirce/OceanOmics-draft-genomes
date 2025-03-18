#!/bin/bash

#list=list.merqury.txt
mkdir -p acacia_stats
out=acacia_stats
acacia_location=pawsey0812:oceanomics-genomes/genomes.v2

mkdir -p mounted_acacia
mounted_acacia=mounted_acacia
# You need to mount acacia to your scratch before the running the script. 
# And then you need to unmount it after you're finished by running 'umount mounted_acacia'
#rclone mount pawsey0812:oceanomics-genomes/genomes.v2 mounted_acacia/ --daemon

### COMPILE completeness stats 

output_file=$out/all_merqury.completeness.stats.tsv
echo -e "Sample\tk-mer_set\tsolid_k-mers\ttotal_k-mers\tcompleteness" > $output_file
#find all .merqury.completeness.stats files 

completeness_files=$(find $mounted_acacia/OG*/kmers/. -name "*.merqury.completeness.stats")        
for i in $completeness_files; do
    cat "$i" >> "$output_file"
  done
 



### COMPILE QV STATS 

output_file=$out/all_merqury.qv.stats.tsv
echo -e "Sample\tunique_k-mers_assembly\tk-mers_total\tQV\terror" > $output_file
#find all .merqury.completeness.stats files 
        completeness_files=$(find $mounted_acacia/OG*/kmers/. -name "*.merqury.qv")
        

for i in $completeness_files; do
     cat "$i" >> "$output_file"
done


#umount $mounted_acacia
