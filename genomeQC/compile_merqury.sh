COMPILE completeness stats 
DATE=
output_file="merqury.completeness.stats.$DATE.tsv"
echo -e "Sample\tk-mer_set\tsolid_k-mers\ttotal_k-mers\tcompleteness" > $output_file
#find all .merqury.completeness.stats files 
completeness_files=$(find . -name "*.merqury.completeness.stats")

        
for i in $completeness_files; do
    cat "$i" >> "$output_file"
  done
 



COMPILE QV STATS 
RUNDIR=
DATE=
output_file="merqury.qv.stats.$DATE.tsv"
echo -e "Sample\tunique_k-mers_assembly\tk-mers_total\tQV\terror" > $output_file
#find all .merqury.completeness.stats files 
        completeness_files=$(find . -name "*.merqury.qv")
        

for i in $completeness_files; do
     cat "$i" >> "$output_file"
done
