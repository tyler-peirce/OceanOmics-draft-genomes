#!/bin/bash --login

# Run these modules the first time you run the script, then comment out
module load nextflow/24.04.3
. ../configfile.txt
# Running the nextflow
nextflow run genome.nf -c nextflow.config -profile setonix -resume -disable-jobs-cancellation -with-report genomeQC.html
