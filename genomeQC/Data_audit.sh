############
# 1. Perform check on local machine 
############
# Perform this check on both the final directory you will back up to Acacia and the final directory you will back up to AWS. 

####
# FINAL WORKFLOW CHECK
####
#1. Generate txt file of OG numbers in directory called OGLIST.txt
# Set the CSV file name
DATE=[seq date]
CSV=draftcheck-workflow-local.$DATE.CSV
# Print the CSV header
echo OGID,LocNum,LocSize,LocBytes | tee -a $CSV

# Read the OGLIST from the specified .txt file
OGLIST_FILE=[Path TO ]/OGLIST.txt

# Loop through each OGID in the OGLIST file
while IFS= read -r OGID; do
  # Get the sizes from rclone for each location
  SIZES=$(echo $(rclone size $OGID | sed 's/Total/|-- Local/g'))
  
  # Format and append the results to the CSV
  echo $OGID $SIZES | sed -E 's/(\(|\))//g' | awk '{print $1,$6,$10 $11,$12;}' | sed 's/ /,/g' | tee -a $CSV
done < "$OGLIST_FILE"


#######
# FINAL LOCAL AWS BACKUP CHECK
#######

DATE=[seq date]
CSV=draftcheck-fasta-aws-local.$DATE.CSV
# Print the CSV header
echo OGID,LocNum,LocSize,LocBytes | tee -a $CSV

# Read the OGLIST from the specified .txt file
OGLIST_FILE=[Path TO ]/OGLIST.txt

# Loop through each OGID in the OGLIST file
while IFS= read -r OGID; do
  # Get the sizes from rclone for each location
  SIZES=$(echo $(rclone size $OGID | sed 's/Total/|-- Local/g'))
  
  # Format and append the results to the CSV
  echo $OGID $SIZES | sed -E 's/(\(|\))//g' | awk '{print $1,$6,$10 $11,$12;}' | sed 's/ /,/g' | tee -a $CSV
done < "$OGLIST_FILE"


###########
# 2. Perform check on acacia to compare with the local workflow check
##########
# Set the CSV file name  
CSV=draftcheck-acacia.$DATE.CSV

#Add headings
echo OGID,AcaNum,AcaSize,AcaBytes | tee -a $CSV

# Read the OGLIST from the specified .txt file
OGLIST_FILE=[PATH TO]/OGLIST.txt


# Loop through each OGID in the OGLIST file
while IFS= read -r OGID; do
  # Get the sizes from rclone for each location
  SIZES=$(echo $(rclone size pawsey0812:oceanomics-genomes/genomes.v2/$OGID | sed 's/Total/|-- Acacia/g'))
  
  # Format and append the results to the CSV
  echo $OGID $SIZES | sed -E 's/(\(|\))//g' | awk '{print $1,$6,$10 $11,$12;}' | sed 's/ /,/g' | tee -a $CSV
done < "$OGLIST_FILE"


###########
# 3. Perform check on aws to compare with the local aws fasta check
###########

DATE=[seq date]
# Set the CSV file name  
CSV=draftcheck-AWS.$DATE.CSV
echo OGID,AwsNum,AwsSize,AwsBytes | tee -a $CSV

# Read the OGLIST from the specified .txt file
OGLIST_FILE=[Path TO]/OGLIST.txt

# Loop through each OGID in the OGLIST file
while IFS= read -r OGID; do
  # Get the sizes from rclone from AWS
  SIZES=$(echo $(rclone size s3:oceanomics/OceanGenomes/analysed-data/draft-genomes/$OGID | sed 's/Total/|-- AWS/g'))
  
  # Format and append the results to the CSV
  echo $OGID $SIZES | sed -E 's/(\(|\))//g' | awk '{print $1,$6,$10 $11,$12;}' | sed 's/ /,/g' | tee -a $CSV
done < "$OGLIST_FILE"
