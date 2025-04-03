#!/bin/bash

mkdir -p aws_stats
out=aws_stats
aws_location=s3:oceanomics/OceanGenomes/analysed-data/draft-genomes

mkdir -p _mounted_SRA
mounted_aws=_mounted_SRA
# You need to mount aws to your scratch before the running the script. 
# And then you need to unmount it after you're finished by running 'umount _mounted_SRA'
#rclone mount s3:oceanomics/OceanGenomes/illumina-sra/ _mounted_SRA/ --daemon

tsv=$out/SRA_stats.tsv
# Print header
echo -e "og_id\tseq_date\trun\tr\tsize\tbase" > $tsv

# Loop through all directories (one level deep)
for f in $mounted_aws/OG*; do
    base=$(basename $f)
    # Extract og_id from directory name or filename
    og_id=$(echo "$base" | cut -d'.' -f1)

    # Extract sequencing date from filenames
    run=$(echo "$base" | cut -d'.' -f3)
    seq_date=$(echo "$run" | cut -d'_' -f2)

    # Extract R1 or R2
    R=$(echo "$base" | cut -d'.' -f4)

    # Get file sizes
    size=$(stat -c%s "$f" 2>/dev/null || echo "0")

    # Print results in tab-separated format
    echo -e "$og_id\t$seq_date\t$run\t$R\t$size\t$base" >> $tsv
done
