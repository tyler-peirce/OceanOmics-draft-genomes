#!/bin/bash --login

#Loading the required modules

module load nextflow/24.04.3

nextflow run assembly.nf -c nextflow.config -profile setonix -resume -disable-jobs-cancellation -with-report assembley.html
