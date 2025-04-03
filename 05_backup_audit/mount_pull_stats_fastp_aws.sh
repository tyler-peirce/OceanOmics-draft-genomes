#!/bin/bash

mkdir -p aws_stats
out=aws_stats
aws_location=pawsey0964:oceanomics-fastq/

mkdir -p _mounted_fastp
mounted_aws=_mounted_fastp
# You need to mount aws to your scratch before the running the script. 
# And then you need to unmount it after you're finished by running 'umount _mounted_fastp'
#rclone mount pawsey0964:oceanomics-fastq/ _mounted_fastp/ --daemon

tsv=$out/fastp_stats.tsv
# Print header
echo -e "og_id\tseq_date\tfastp_r1\tfastp_r1_size\tfastp_r2\tfastp_r2_size" > $tsv

# Loop through all directories (one level deep)
for dir in $mounted_aws/OG*/fastp/; do
    # Remove trailing slash from directory name
    dir=${dir%/}

    # Find the files matching the patterns
    r1_path=$(ls "$dir"/*R1*.gz 2>/dev/null | head -n 1)
    r2_path=$(ls "$dir"/*R2*.gz 2>/dev/null | head -n 1)

    # Extract only the filename (basename)
    r1_file=$(basename "$r1_path" 2>/dev/null || echo "NA")
    r2_file=$(basename "$r2_path" 2>/dev/null || echo "NA")

    # Extract og_id from directory name or filename
    og_id="UNKNOWN"
    if [[ "$r1_file" != "NA" ]]; then
        og_id=$(echo "$r1_file" | cut -d'.' -f1)
    fi

    # Extract sequencing date from filenames
    seq_date="UNKNOWN"
    if [[ "$r1_file" != "NA" ]]; then
        seq_date=$(echo "$r1_file" | cut -d'.' -f3)
    fi

    # Get file sizes
    r1_size=$(stat -c%s "$r1_path" 2>/dev/null || echo "0")
    r2_size=$(stat -c%s "$r2_path" 2>/dev/null || echo "0")

    # Print results in tab-separated format
    echo -e "$og_id\t$seq_date\t$r1_file\t$r1_size\t$r2_file\t$r2_size" >> $tsv
done
