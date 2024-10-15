#!/bin/bash

# Load in the configfile
. ../configfile.txt

##################################
#This script checks if the filtering has been carried put but checking if 
#a) the required filtered fasta file has been generated for the next step &
#b) that the file has contents
################################### 

# Create a new file to store the existence status and content status of the fasta file
echo "Directory Path   Fasta File Exists   Fasta File Status" > fasta_file_status.txt

for i in $rundir/*; do
    if [ -d "$i" ]; then
        sample=$(basename "$i")
        assembly=$(basename "$i").ilmn.$DATE
        fasta=$rundir/$sample/assemblies/genome/$assembly.rmadapt.fasta

        # Check if the fasta file exists
        if [ -f "$fasta" ]; then
            exists="Exists"
            
            # Check if the fasta file is empty or has contents
            if [ -s "$fasta" ]; then
                status="Has Contents"
            else
                status="Empty"
            fi
        else
            exists="Does Not Exist"
            status="N/A"
        fi

        # Print the directory path, fasta file existence, and content status
        echo "$i   $exists   $status" >> fasta_file_status.txt
    fi
done
