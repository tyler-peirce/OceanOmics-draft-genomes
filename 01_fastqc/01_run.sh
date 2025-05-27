#!/bin/bash

module load nextflow/24.04.3

nextflow run fastqc.nf -c nextflow.config -profile setonix -resume -disable-jobs-cancellation -with-report fastqc.html
