#!/bin/bash

# Load in the configfile
. ../configfile.txt


#1. Perform check on local machine 

# Generate txt file with list of OGID into a txt file called OGLIST_SRA.txt
OGLIST_FILE=$results/OGLIST_SRA.txt
ls $pooled > $OGLIST_FILE

# Set the TSV file name  
TSV_L=$results/draftSRAcheck-local.$DATE.TSV

# Print the TSV header
echo -e "OGID\tLocNum\tLocSize\tLocBytes" | tee -a $TSV_L

# Loop through each OGID in the OGLIST file
while IFS= read -r OGID; do
  # Get the sizes from rclone for each location
  SIZES_LOCAL=$(echo $(rclone size $pooled/$OGID | sed 's/Total/|-- Local/g'))
  
  # Format and append the results to the TSV
  echo $OGID $SIZES_LOCAL | sed -E 's/(\(|\))//g' | awk '{print $1,$6,$10 $11,$12;}' | sed 's/ /\t/g' | tee -a $TSV_L
done < "$OGLIST_FILE"


## 2. Perform check on aws

# Set the TSV file name  
TSV_A=$results/draftSRAcheck-AWS.$DATE.TSV

# Print the TSV header
echo -e "OGID\tLocNum\tLocSize\tLocBytes" | tee -a $TSV_A

# Loop through each OGID in the OGLIST file
while IFS= read -r OGID; do
  # Get the sizes from rclone from AWS
  SIZES_AWS=$(echo $(rclone size s3:oceanomics/OceanGenomes/illumina-sra/$OGID | sed 's/Total/|-- AWS/g'))
  
  # Format and append the results to the TSV
  echo $OGID $SIZES_AWS | sed -E 's/(\(|\))//g' | awk '{print $1,$6,$10 $11,$12;}' | sed 's/ /\t/g' | tee -a $TSV_A
done < "$OGLIST_FILE"

# join the two for comparison
paste -d '\t' $TSV_L $TSV_A > $results/draftSRAcheck-join.$DATE.TSV