#!/bin/bash

# Load in the configfile
. ../configfile.txt


#1. Perform check on local machine 

# Generate txt file with list of OGID into a txt file called OGLIST_SRA.txt
OGLIST_FILE=$results/OGLIST_SRA.txt
ls $pooled > $OGLIST_FILE

# Set the CSV file name  
CSV=$results/draftSRAcheck-local.$DATE.CSV

# Print the CSV header
echo OGID,LocNum,LocSize,LocBytes | tee -a $CSV

# Loop through each OGID in the OGLIST file
while IFS= read -r OGID; do
  # Get the sizes from rclone for each location
  SIZES_LOCAL=$(echo $(rclone size $pooled/$OGID | sed 's/Total/|-- Local/g'))
  
  # Format and append the results to the CSV
  echo $OGID $SIZES_LOCAL | sed -E 's/(\(|\))//g' | awk '{print $1,$6,$10 $11,$12;}' | sed 's/ /,/g' | tee -a $CSV
done < "$OGLIST_FILE"


## 2. Perform check on aws

# Set the CSV file name  
CSV=$results/draftSRAcheck-AWS.$DATE.CSV

# Print the CSV header
echo OGID,AwsNum,AwsSize,AwsBytes | tee -a $CSV

# Loop through each OGID in the OGLIST file
while IFS= read -r OGID; do
  # Get the sizes from rclone from AWS
  SIZES_AWS=$(echo $(rclone size s3:oceanomics/OceanGenomes/illumina-wgs/$RUN/$OGID | sed 's/Total/|-- AWS/g'))
  
  # Format and append the results to the CSV
  echo $OGID $SIZES_AWS | sed -E 's/(\(|\))//g' | awk '{print $1,$6,$10 $11,$12;}' | sed 's/ /,/g' | tee -a $CSV
done < "$OGLIST_FILE"
