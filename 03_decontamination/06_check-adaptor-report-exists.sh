#!/bin/bash

# Load in the configfile
. ../configfile.txt

# Create a new file to store the existence status of action_report
echo "Directory Path   Action Report Exists" > action_report_exists.txt

for i in $rundir/*; do
    if [ -d "$i" ]; then
        sample=$(basename "$i")
        assembly=$(basename "$i.ilmn.$DATE")
        fasta="$rundir/$sample/assemblies/genome/$assembly.v129mh.fa"
        out_dir="$rundir/$sample/assemblies/genome"
        action_report="$rundir/$sample/assemblies/genome/NCBI/adaptor/fcs_adaptor_report.txt"

        # Check if the action_report file exists
        if [ -f "$action_report" ]; then
            status="Exists"
        else
            status="Does Not Exist"
        fi

        # Print the directory path and whether action_report exists or not
        echo "$i   $status" >> action_report_exists.txt
    fi
done
