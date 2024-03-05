# Overview 

This documentation describes a nextflow pipeline for quality control and de novo genome assembly of illumina genomes. 

# Requirements 

The scripts included here are designed to run using singularity containers on a HPC cluster using the workload manager SLURM. 

# User guide 

There are three main nextflow scripts to run the genome assembly pipeline, each step will generate a set of statistics that can be compiled in either .tsv format or .tdt format using the tsv.compile code. 
This pipeline assumes you have paired end illumina reads, with lanes pooled together. 

# Reads Quality Control

The fastqc directory contains the first part of the nextflow pipeline, which takes raw reads with lanes pooled together and runs programs fastqc fastp and multiqc, and includes an R script to compile results from the fastp json file. The nextflow.config file outlines the singulairy containers used in each step as well as slurm script settings. After you have cloned the repo onto your scratch you can run the nextflow from within the fasqc folder. To run the nextflow module update the file paths for the raw reads in the fastqc.nf script the output paths to the desired location. Submit the slurm.sh script ensuring you have loaded both the singularity module and nextflow module and have updated name for the html report. 

# Genome Assembly

The assembly directory contains the second part of the nextflow pipeline, which takes the filtered and trimmed reads output from the previous nextflow. The assembly.nf script runs programs meryl, GenomeScope and MEGAHIT. The nextflow.config outlines the singulairty containers used in each step as well as the slurm script settings. This nextflow can be run from within the assembly directory. To run the nextflow module update the file paths for the filtered and trimmed reads in the assembly.nf script and the output paths to the desired location. Submit the slurm.sh script ensuring you have loaded both the singularity module and nextflow module and have updated name for the html report.

# Decontamination 

Following genome assembly two separate genome decontamination tools are used to detect and remove any foreign contaminates from within the genome. Scripts for these can be found in the decontamination folder. 

**1. NCBI fcs (foreign contaminant screen).** 
This tool screens the genome against NCBI databases and searches for contaminants in the genome based off the NCBI taxonomy number given in the script. The example script contains the NCBI taxon ID for Actinopterygii (Ray fin fishes). Please ensure you update this number in the script based off the genome you are working on. 

There are 2 scripts for this process
  1. The first script screens the genome and generates a report containing all contaminates found. This report is split into 3 categories that any contig can fit within, (EXCLUDE, TRIM & REVIEW). 
  2. The second script uses reviews this report and removes all contigs marked as EXCLUDE, removes any contigs that are less than >1000BP marked as REVIEW, & finally filters out any contigs that are less than 500BP from the assembly. At the   
     same time this script will run a series of bash commands to summaries the number of contigs and number of BP removed at each step. These will be printed in 3 tsv files:
     **$sample_NCBI_filter_report.tsv:**  report that showing the number of contigs filtered as well as the total number of BP filtered, it also prints the number of contigs that are less than 1000bp in the REVIEW sections of the report and the
     total bp of those contigs
     **$sample_NCBI_contig_count_500bp.tsv** : this prints the number of contigs in sample that have less than 500bp 


To run these scripts please refer to scripts NCBI_find_contam.sh NCBI_filter. If you are running this across a large amount of files please see the NCBI farming scripts, which contain loops to submit one slurm job per assembly file.

The filtered fasta file will have an .fa extension and is to be used in the next decontamination process. 


**3. Tiara decontamination **
This tool searches the NCBI decontaminated genome for additional contamination particularity Mitochondrial. 
There are 2 scripts for this process 

The first script screens the genome and outputs three fasta files with the mitochondrial, plastid and protist contigs which it deems to be contamination. 
The second script compiles the contamination into a report, showing the type, number of contigs and how many base pairs. This report is then used with  BBMap to filter out the contaminate contigs. 
These reports are to be pushed to github to be held in the database.


To run these scripts please refer to tiara_find_contam.sh filter_tiara.sh for slurm scripts and to the tiara farming scripts which contain loops to submit one slurm job per assembly file


The final decontaminated fasta file will have a .fna extension, this is to be used for genome QC and downstream processes.




