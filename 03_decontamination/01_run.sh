#!/bin/bash 

module load nextflow/24.04.3

# Running the nextflow
nextflow run decontamination.nf -c nextflow.config -profile setonix -resume -disable-jobs-cancellation -with-report decontamination.html
