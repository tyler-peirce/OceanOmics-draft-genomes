#!/bin/bash

mkdir -p aws_stats
out=aws_stats
aws_location=s3:oceanomics/OceanGenomes/illumina-raw/

mkdir -p _mounted_aws
mounted_aws=_mounted
# You need to mount aws to your scratch before the running the script. 
# And then you need to unmount it after you're finished by running 'umount mounted_aws'
#rclone mount s3:oceanomics/OceanGenomes/illumina-raw/ _mounted/ --daemon

tsv=$out/aws_raw_stats.tsv
# Print header
echo -e "og_id\tseq_date\taws_r1\taws_r1_size\taws_r2\taws_r2_size\taws_assm\taws_assm_size" > $tsv

# Loop through all directories (one level deep)
for dir in $mounted_aws/OG*/; do
    # Remove trailing slash from directory name
    dir=${dir%/}

    # Find the files matching the patterns
    r1_path=$(ls "$dir"/*R1* 2>/dev/null | head -n 1)
    r2_path=$(ls "$dir"/*R2* 2>/dev/null | head -n 1)
    assm_path=$(ls "$dir"/*.fna 2>/dev/null | head -n 1)

    # Extract only the filename (basename)
    r1_file=$(basename "$r1_path" 2>/dev/null || echo "NA")
    r2_file=$(basename "$r2_path" 2>/dev/null || echo "NA")
    assm_file=$(basename "$assm_path" 2>/dev/null || echo "NA")

    # Extract og_id from directory name or filename
    og_id="${dir}"
    if [[ "$assm_file" != "NA" ]]; then
        og_id=$(echo "$assm_file" | cut -d'.' -f1)
    fi

    # Extract sequencing date from filenames
    seq_date="UNKNOWN"
    if [[ "$assm_file" != "NA" ]]; then
        seq_date=$(echo "$assm_file" | cut -d'.' -f3)
    fi

    # Get file sizes
    r1_size=$(stat -c%s "$r1_path" 2>/dev/null || echo "0")
    r2_size=$(stat -c%s "$r2_path" 2>/dev/null || echo "0")
    assm_size=$(stat -c%s "$assm_path" 2>/dev/null || echo "0")

    # Print results in tab-separated format
    echo -e "$og_id\t$seq_date\t$r1_file\t$r1_size\t$r2_file\t$r2_size\t$assm_file\t$assm_size" >> $tsv
done
