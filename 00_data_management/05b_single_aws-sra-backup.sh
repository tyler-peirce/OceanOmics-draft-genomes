#!/bin/bash
## This code is an alternative and will submit jobs to the copy que for each file to make the copying quicker.
. ../configfile.txt
# Define your pooled directory if not already exported in configfile
#pooled="/scratch/pawsey0964/tpeirce/_DRAFTGENOMES/pooled"  # Replace this if $pooled is not already defined
s3bucket="s3:oceanomics/OceanGenomes/illumina-sra/"

# Create a jobs directory
mkdir -p rclone_jobs

# Loop through each file in the pooled directory
for file in "$pooled"/*; do
    filename=$(basename "$file")
    jobscript="rclone_jobs/rclone_${filename}.sbatch"

    # Create SLURM job script
    cat > "$jobscript" <<EOF
#!/bin/bash
#SBATCH --job-name=rclone_${filename}
#SBATCH --output=rclone_jobs/%x.out
#SBATCH --error=rclone_jobs/%x.err
#SBATCH --ntasks=1
#SBATCH --time=02:00:00
#SBATCH --partition=copy
#SBATCH --account=pawsey0964  # Replace with your project allocation code

echo "Starting upload of $file"
rclone copy "$file" "$s3bucket" --checksum
EOF

    # Submit the job
    sbatch "$jobscript"
done
