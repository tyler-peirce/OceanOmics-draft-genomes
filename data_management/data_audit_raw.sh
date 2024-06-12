

#####
###1. Perform check on local machine 
#####

# Generate txt file with list of OGID into a txt file called OGLIST.txt
DATE=[date of seq run]

# Set the CSV file name  
CSV=draftRAWcheck-local.$DATE.CSV

# Print the CSV header
echo OGID,LocNum,LocSize,LocBytes| tee -a $CSV

# Read the OGLIST from the specified .txt file
OGLIST_FILE=[PATH TO]/OGLIST.txt

# Loop through each OGID in the OGLIST file
while IFS= read -r OGID; do
  # Get the sizes from rclone for each location
  SIZES=$(echo $(rclone size $OGID | sed 's/Total/|-- Local/g'))
  
  # Format and append the results to the CSV
  echo $OGID $SIZES | sed -E 's/(\(|\))//g' | awk '{print $1,$6,$10 $11,$12;}' | sed 's/ /,/g' | tee -a $CSV
done < "$OGLIST_FILE"



1. Perform check on aws

DATE=[date of seq run]

RUNID=(name of the run that it was backed up as, for example NOVA_230814_LP) 

echo OGID,AwsNum,AwsSize,AwsBytes | tee -a $CSV
# Set the CSV file name  
CSV=draftRAWcheck-AWS.$DATE.CSV

# Read the OGLIST from the specified .txt file
OGLIST_FILE=[PATH TO]/OGLIST.txt


# Loop through each OGID in the OGLIST file
while IFS= read -r OGID; do
  # Get the sizes from rclone from AWS
  SIZES=$(echo $(rclone size s3:oceanomics/OceanGenomes/illumina-raw/$RUNID/$OGID | sed 's/Total/|-- AWS/g'))
  
  # Format and append the results to the CSV
  echo $OGID $SIZES | sed -E 's/(\(|\))//g' | awk '{print $1,$6,$10 $11,$12;}' | sed 's/ /,/g' | tee -a $CSV
done < "$OGLIST_FILE"
