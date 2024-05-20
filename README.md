# OceanOmics Draft Genome Assembly Pipeline

# Overview 

This documentation describes a nextflow pipeline for quality control and de novo genome assembly of illumina genomes. 



![draft genome pipeline git3 drawio](https://github.com/LaurenHuet/OceanOmics-draft-genomes/assets/88010555/2371ce95-e351-4abd-80f5-85f759a131ea)


# Requirements 
The scripts included here are designed to run using singularity containers on a HPC cluster using the workload manager SLURM. 

# User guide 

There are three main nextflow scripts to run the genome assembly pipeline, each step will generate a set of statistics that can be compiled in either .tsv format or .tdt format using the tsv.compile code. 
This pipeline assumes you have paired end illumina reads, with lanes pooled together. Please ensure you are familiar with the requirements of storing results in the ogl_ilmn_database, all results from OceanOmics Draft Genomes pipeline will need to be pushed to this git for storage in the sql database (https://github.com/Computational-Biology-OceanOmics/olg_ilmn_database/tree/main).

# Reads Quality Control

The fastqc directory contains the first part of the nextflow pipeline, which takes raw reads with lanes pooled together and runs programs fastqc fastp and multiqc, and includes an R script to compile results from the fastp json file. The nextflow.config file outlines the singularity containers used in each step as well as slurm script settings. After you have cloned the repo onto your scratch you can run the nextflow from within the fasqc folder. To run the nextflow module update the file paths for the raw reads in the fastqc.nf script the output paths to the directory structure outlined below. Submit the slurm.sh script ensuring you have loaded both the singularity module and nextflow module and have updated name for the html report. Within this directory you will find a fastp-compile.sh script. This will gather the outputs across a run and compile them into a list which will be pushed into the sql database.

Directory structure
```
Project-dir/  
└── OG303  
    └── fastp
            *fastq.gz
         └── fastqc
                *fastqc-stats*
``` 
At the end of the fastqc nextflow you should have a directory structure like this, with the filtered and trimmed fastq files in the fastp directory, and the results of fastqc in the fastqc directory. 
Run the fastqc-backup.sh script to backup filtered and trimmed reads to acacia. 

# Genome Assembly

The assembly directory contains the second part of the nextflow pipeline, which takes the filtered and trimmed reads output from the previous nextflow. The assembly.nf script runs programs meryl, GenomeScope and MEGAHIT. The nextflow.config outlines the singularity containers used in each step as well as the slurm script settings. This nextflow can be run from within the assembly directory. To run the nextflow module update the file paths for the filtered and trimmed reads in the assembly.nf script and the output paths to the directory structure below. Submit the slurm.sh script ensuring you have loaded both the singularity module and nextflow module and have updated name for the html report. Within this directory you will find a genomescope-compile.sh script. This will gather the outputs across a run and compile them into a list which will be pushed into the sql database.

Directory Structure

```
project-dir/
└── OG303
    ├── assemblies
    │   └── genome
                *fasta
    ├── fastp
    │   └── fastqc
    └── kmers
            *genomescope-results-dir*
            *meryldb
```

At the end of the assembly nextflow pipeline you should have a directory structure like this, with a assembly *.fasta file in the genome folder. GenomScope output in a directory in the kmers directory, and a meryl database in the kmers directory. 

# Decontamination 

Following genome assembly three separate genome decontamination tools are used to detect and remove any foreign contaminates from within the genome. Scripts for these can be found in the decontamination folder. 

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
the NCBI compile scripts will compile the results of the NCBI decontamination step, to be pushed into the sql database. 

The filtered fasta file will have an *.fa extension and is to be used in the next decontamination process. 

**2. NCBI Adaptor contamination removal**
This tool searches the *.fa decontaminated genome for any adaptor and vector contaminaion. There are 2 main scripts for this tool. 
    1. find-adaptors.sh, which can be used with farm_find-adaptor-contam.sh. This script will search the genome for adaptor contamination and produce a 
    adaptor-report.txt file to be used to clean the genome of adaptor contamination. The script check-adaptor-report-exists.sh can be run to check if this process     has been successful before moving onto the next step. 
    2. filter-adaptors.sh, which can be used with farm_filter-adaptors.sh, will clean the adaptor contamination from the genome. Upon successful completion of         this step you will have a fasta file in the genomes dirctory called $assembly.rmadapt.fasta, which will be used in the next process. To ensure this has             compleated succesfuly the script check-rmadapt-exists.sh will search for the *.fasta file, check for contents and prints a .txt file with these results.


**3. Tiara decontamination**
This tool searches the NCBI decontaminated genome for additional contamination particularity Mitochondrial. 
There are 2 scripts for this process 

The first script screens the genome and outputs three fasta files with the mitochondrial, plastid and protist contigs which it deems to be contamination. 
The second script compiles the contamination into a report, showing the type, number of contigs and how many base pairs. This report is then used with BBMap to filter out the contaminate contigs. 
These reports are to be compile with the tiara-compile.sh scripts and pushed to github to be held in the database.


To run these scripts please refer to tiara_find_contam.sh filter_tiara.sh for slurm scripts and to the tiara farming scripts which contain loops to submit one slurm job per assembly file


The final decontaminated fasta file will have a .fna extension, this is to be used for genome QC and downstream processes.

Directory Structure 
```
project-dir/
└── OG303
    ├── assemblies
    │   └── genome
    │       ├── *.fa
    │       ├── *.fasta
    │       ├── *.fna
    |       ├── *.rmadapt.fasta
    │       ├── NCBI
    |       |   └── adaptor
    │       └── tiara
    ├── fastp
    │   └── fastqc
    └── kmers

```

At the end of the decontamination script you should the output of the NCBI decontamination and the output if the tiara decontamination in their directories, and the intermediate fasta files in the genomes directory, where the *.fasta was the inital assembly, the *.fa is the assembly after NCBI decontamination, and the *.fna is the final decontaminated fasta after both NCBI and tiara decontamination.

At the end of this step, run the final_aws_backup.sh script to back up the final genome assembly file and filtered and trimmed reads to AWS.

# Genome Quality Metrics

The following workflow will run through a series of tools to obtain quality metrics for the assembly quality of the genome. Upon completion, results are to be compiled and pushed to the olg_ilmn_database. 

This workflow can be run from the Genome QC nextflow , or as a series of scripts farmed out across a run.

**GenomeQC Nextflow**

It is important that you have followed the directory structure of the previous nextflows to continue on with this workflow. The genomeQC directory contains the nextflow pipeline, which takes the decontaminated genome, meryl database and fastq files as input. the genome.nf script runs programs BUSCO, BWA/Samtools, Merqury and Depthsizer. The nextflow.config outlines the singulairty containers used in each step as well as the slurm script settings. The bin directory contains an R script to compile results from BUSCO.  This nextflow can be run from within the genomeQC directory. To run the nextflow module update the project directory path. Submit the slurm.sh script ensuring you have loaded both the singularity module and nextflow module and have updated name for the html report.

Please note that there are two busco processes in this nextflow, one that uses the actinopterygii_odb10 and one that uses the vertebrata_odb10, please ensure you are using the correct database for the samples you are processing. The two processes have been added to make it easier to get the correctly named outputs without having to edit the scripts. 

```
project-dir/
└── OG303
    ├── assemblies
    │   └── genome
    │       ├── NCBI
    │       ├── busco_acti
    │       ├── bwa
    │       ├── depthsizer
    │       └── tiara
    ├── fastp
    │   └── fastqc
    └── kmers

```

At the end of the piepline you should have a directory structure like this, with results from BWA, depthsizer and busco in directories within the genome directory, and the results of Merqury will be within the kmers directory. To compile these results and push them to the SQL database, please refer to the instructions below for locations of the compilation scripts. 

Run the final-genome-backup.sh script in the genomeQC directory to back up these results to acacia, only run this after you have compiled the stats.


**Alternatively**, the workflow can be ran as a series of scripts farmed out across a run (project-directory)
The following tools are to be incorporated into the QC workflow, please refer to the stand alone scripts within each of the following directories to farm these jobs out across each run. 

**BUSCO 
BWA 
Merqury
DepthSizer**

**BUSCO**
To run BUSCO please ensure you know what species you are working with, as the database you use for BUSCO will depend on your species. If you are working on Actinoptergii, this database is stored locally on pawsey in the the  /software/projects/pawsey/singularity path. If you require a different database please refer to https://busco.ezlab.org/ to install this locally. 

Please refer to the busco.sh script to run busco independently or the busco-farming.sh to farm jobs out across a RUN of samples. 

Please refer to the compile busco results for a series of scripts that will convert JSON busco results into TSV files and compile those across runs to generate a table of results for the sql database. 


**BWA**
This step is to map the reads back to the assembly file generating a sorted bam file to be used for downstream processes. 

Please refer to BWA.sh to run BWA independently or bwa-famring.sh to farm jobs out across a RUN of samples. 


**Samtools stats**
This step is to check the coverage of the assembly. Please refer to the samtools_stats.sh script to run independently or samtools-farming.sh to farm jobs out across a RUN of samples, these scripts are located within the BWA directory.


**Merqury**
This tool looks at the completeness and QV score of the assembly, please see Merqury.sh for scripts to run independently or merqury-farming.sh to farm jobs out across a RUN of samples. 

Please refer to compile_merqury.sh to compile the completeness an QV scores for the SQL database. 


**Depthsizer**
This tool estimates the genome size of the assembly. Please see Depthsizer.sh run independently or depthsizer-famring.sh to farm jobs out across a RUN of samples.

Please refer to compile_depthsizer.sh to compile the genome size prediction stats for each sample for the SQL database. 
