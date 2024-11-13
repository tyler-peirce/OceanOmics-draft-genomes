#!/bin/bash

# Load in the configfile
. ../configfile.txt

#######
# LOCAL AWS BACKUP CHECK
#######

tsv_loc=$results/draftcheck-AWS-local.$DATE.tsv
# Print the tsv header
echo -e "OGID\tLocNum\tLocSize\tLocBytes" | tee $tsv_loc

# Read the OGLIST from the specified .txt file
OGLIST_FILE=$results/OGLIST.txt
ls $rundir > $OGLIST_FILE


# Loop through each OGID in the OGLIST file
while IFS= read -r OGID; do
  # Get the sizes from rclone for each location
  SIZES=$(echo $(rclone size $AWS/$OGID | sed 's/Total/|-- Local/g'))
  
  # Format and append the results to the CSV
  echo $OGID $SIZES | sed -E 's/(\(|\))//g' | awk '{print $1,$6,$10 $11,$12;}' | sed 's/ /\t/g' | tee -a $tsv_loc
done < "$OGLIST_FILE"

###########
# Perform check on aws to compare with the local aws fasta check
###########

# Set the TSV file name  
TSV_WF=$results/draftcheck-AWS.$DATE.tsv
echo -e "OGID\tLocNum\tLocSize\tLocBytes" | tee $TSV_WF

# Read the OGLIST from the specified .txt file
OGLIST_FILE=$results/OGLIST.txt

# Loop through each OGID in the OGLIST file
while IFS= read -r OGID; do
  # Get the sizes from rclone from AWS
  SIZES=$(echo $(rclone size s3:oceanomics/OceanGenomes/analysed-data/draft-genomes/$OGID | sed 's/Total/|-- AWS/g'))
  
  # Format and append the results to the CSV
  echo $OGID $SIZES | sed -E 's/(\(|\))//g' | awk '{print $1,$6,$10 $11,$12;}' | sed 's/ /\t/g' | tee -a $TSV_WF
done < "$OGLIST_FILE"

###########
# Join the two tables together to make comparison easier
###########
join -t $'\t' $tsv_loc $TSV_WF > $results/draftcheck-AWS-join.$DATE.tsv