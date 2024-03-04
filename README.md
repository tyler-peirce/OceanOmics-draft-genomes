# Overview 

This documentation describes a nextflow pipeline for quality control and de novo genome assembly of illumina genomes. 

# Requirements 

The scripts included here are designed to run using singularity containers on a HPC cluster using the workload manager SLURM. 

# User guide 

There are three main nextflow scripts to run the genome assembly pipeline, each step will generate a set of statistics that can be compiled in either .tsv format or .tdt format using the tsv.compile code. 
This pipeline assumes you have paired end illumina reads, with lanes pooled together. 
