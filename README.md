# OceanOmics Draft Genome Assembly Pipeline

# Overview 

This documentation describes a nextflow pipeline for quality control and de novo genome assembly of illumina genomes. 



![draft genome pipeline git3 drawio](https://github.com/LaurenHuet/OceanOmics-draft-genomes/assets/88010555/2371ce95-e351-4abd-80f5-85f759a131ea)


# Requirements 
The scripts included here are designed to run using singularity containers on a HPC cluster using the workload manager SLURM. 

# User guide 

The genome assembly pipeline consists of four main Nextflow scripts, each generating a set of statistics that can be compiled into either .tsv or .tdt format using tsv.compile. This pipeline is designed for paired-end Illumina reads with pooled lanes. Ensure you are familiar with the requirements for storing results in the ogl_ilmn_database. All outputs from the OceanOmics Draft Genomes pipeline should be pushed to this Git repository for SQL database storage: ogl_ilmn_database GitHub.

A configfile.txt in the main directory needs updating with the specific run details. This file is read by Nextflow and bash scripts to minimise the need for manual script edits and reduced errors.

Within each directory, files are numbered in the order they should be run. Nextflow scripts can be submitted via the SLURM script or executed in a TMUX session on the workflow node on Pawsey by copying the line of code in the 01_slurm.sh script (or an equivelent terminal on your system).

The nextflow.config file specifies the Singularity containers and SLURM settings for each step. These settings or cantainers can be updated in this file.

# Config File
After the repository has been cloned from git onto your scratch, you need to update the configfile.txt in the main directory. There are instructions within the file. Once these have been updated you should not have to change any of the other scripts.

# Data Management

The 00_data_management directory contains scripts for managing sequencing data which have been numbered in the order they should be run:

01: Download sequencing runs from BaseSpace.
02 & 03: Back up raw data and perform an audit to verify file sizes after copying. Adapt these scripts as needed for your data management system.
04: Pools multiple lanes together, reading in 04a as part of this process.
05 & 06: Back up the pooled data and conduct an audit to ensure data integrity.

# Reads Quality Control

The 01_fastqc directory contains the first part of the Nextflow pipeline, which processes raw reads with pooled lanes through fastqc, fastp, and multiqc. An R script is also included to compile results from the fastp JSON file.

Submit 01_slurm.sh, or run in the workflow node terminal, making sure to load the Singularity and Nextflow modules.

The 02_fastp-compile.sh script is then run to aggregate outputs across a run, which can then be pushed to the SQL database.

Expected Directory Structure after running the Nextflow:

```
Project-dir/  
└── OG303  
    └── fastp
         *fastq.gz
         └── fastqc
             *fastqc-stats*
```

Upon completion, the directory should contain filtered and trimmed .fastq files in the fastp directory and fastqc results in the fastqc directory.

Use 03_fastqc-backup.sh to back up filtered and trimmed reads to Acacia.

# Genome Assembly

The assembly directory contains the second part of the nextflow pipeline, which uses the filtered and trimmed reads from the previous nextflow. (the *fastq.gz files in the fastp directory)

The assembly.nf script runs the programs: meryl, GenomeScope and MEGAHIT. 

Submit 01_slurm.sh, or run in the workflow node terminal, making sure to load the Singularity and Nextflow modules.

Run the 02_genomescope-compile.sh script to compile the outputs across a run, which can then be pushed to the SQL database.

Expected Directory Structure after running the Nextflow:

```
Project-dir/
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

At the end of the assembly nextflow pipeline you should have a directory structure like the one above, with an assembly *.fasta file in the genome folder. GenomScope output in a directory within the kmers directory, and a meryl database in the kmers directory. 


# Decontamination 

The decontamination nextflow is the third step of the pipeline, which will use three separate genome decontamination tools to detect and remove any foreign contaminates from within the genome. 

Note: there is a repullfatp.sh script to re pull the fastp files if they have been deleted.

Firstly, you will need to run the species check in the 00_species_check directory. The nomspecies.txt file will need updating to ensure all the OG numbers are captured. To update this file copy the OG number and nominal species ID columns from the lab database into this file and save. Then run the 01_speciescheck.sh script. This script uses TAXONKIT to determine if its a fish or a vertebrate and finds the taxon ID. There are some instrucrtions within this script that need executing if it is the first time you are running this script.

You need to go and check the taxon.txt output from the 01_speciescheck.sh to ensure that each sample has been assigned either 'vertebrate' or 'actinopterygii' and that it has a taxon id number. If these are missing you need to manually enter them into the file, making sure to put it in the right tab deliminated column.

Once complete, you can then run the nextflow by submitting 01_slurm.sh, or run in the workflow node terminal, making sure to load the Singularity and Nextflow modules.

The following is a description of what each process in the nextflow does:

**1. NCBI fcs (foreign contaminant screen).** 
This tool screens the genome against NCBI databases and searches for contaminants in the genome based off the NCBI taxonomy number. 

There are 2 processes for this:
  1. The fcs-gx tool screens the genome and generates a report containing all contaminates found. This report is split into 3 categories that any contig can fit within, (EXCLUDE, TRIM & REVIEW). 
  2. The fcs-gx clean, reviews this report and removes all contigs marked as EXCLUDE, removes any contigs that are less than >1000BP marked as REVIEW, & finally filters out any contigs that are less than 500BP from the assembly. 
  
**2. bbmap filter**  
This process will run a series of bash commands to summaries the number of contigs and number of BP removed at each step. These will be printed in 3 tsv files:
     **$sample.filter_report.tsv:**  report that showing the number of contigs filtered as well as the total number of BP filtered, it also prints the number of contigs that are less than 1000bp in the REVIEW sections of the report and the
     total bp of those contigs
     **$sample.contig_count_500bp.tsv** : this prints the number of contigs in sample that have less than 500bp 
     **$sample.review_scaffolds_1kb.txt**: this prints the contigs that are in review and less than 1000bp
bbmap then uses these files to filter out these contigs. The filterbyname.sh step outputs **$sample.rf.fa** which uses the **$sample.review_scaffolds_1kb.txt** to remove these contigs. The reformat.sh step then removes all the contigs under 500bp leaving the **$sample.fa** file.


The filtered fasta file will have an *.fa extension and is to be used in the next decontamination process. 

**2. NCBI Adaptor contamination removal**
This tool searches the *.fa decontaminated genome for any adaptor and vector contaminaion. There are 2 main processes for this tool. 
    1. The first will search the genome for adaptor contamination and produce a 
    adaptor-report.txt file to be used to clean the genome of adaptor contamination. 
    2. filter-adaptors will clean the adaptor contamination from the genome. Upon successful completion of this step you will have a fasta file in the genomes dirctory called $assembly.rmadapt.fasta, which will be used in the next process. 


**3. Tiara decontamination**
This tool searches the NCBI decontaminated genome for additional contamination particularity Mitochondrial. 

The first process screens the genome and outputs three fasta files with the mitochondrial, plastid and protist contigs which it deems to be contamination. It then compiles the contamination into a report, showing the type, number of contigs and how many base pairs. 


**4. bbmap filtering**
The report from the tiara decontamination process is then used with BBMap to filter out the contaminate contigs. 

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

At the end of the decontamination nextflow pipline you should have a directory structure like the one above. With sepperate directories for the tiara results and the NCBI adaptor contamination. The intermediate fasta files should be in the genomes directory, where the *.fasta was the inital assembly, the *.fa is the assembly after NCBI decontamination, and the *.fna is the final decontaminated fasta after both NCBI and tiara decontamination.

At the end of this step, run the 04_final_aws_backup.sh script to back up the final genome assembly file and the filtered and trimmed reads to AWS.

Then run the 05_Data_audit_AWS script, this will calculate the number of files and the size of each directory for: the local AWS backup directory, and the backed up files on AWS. You are able to then check that everything has been copied fully over to AWS.

# Genome Quality Metrics

The following workflow will run through a series of tools to obtain quality metrics for the assembly quality of the genome. Upon completion, results are to be compiled and pushed to the olg_ilmn_database. 

This workflow can be run from the Genome QC nextflow, or as a series of scripts farmed out across a run.

**GenomeQC Nextflow**

It is important that you have followed the directory structure of the previous nextflows to continue on with this workflow. The 04_genomeQC directory contains the nextflow pipeline, which takes the decontaminated genome, meryl database and fastq files as input. the genome.nf script runs the programs: BUSCO, BWA/Samtools, Merqury and Depthsizer. 

Submit 01_slurm.sh, or run in the workflow node terminal, making sure to load the Singularity and Nextflow modules.

Please note that there are two busco and bwa processes in this nextflow, one that uses the actinopterygii_odb10 and one that uses the vertebrata_odb10. The pipeline will read in the taxon.txt file created in the decontamination step using the 01_species_check.sh script in the 00_species_check directory. Make sure that each line in this file has successfully been assigned 'vertebrate' or 'actinopterygii'. If it hasnt successfully been assigned one, edit this file with the correct assignment.


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

At the end of the piepline you should have a directory structure as above, with results from BWA, depthsizer and busco in directories within the genome directory, and the results of Merqury will be within the kmers directory. 

To compile these results run the scripts 02a, 02b, and 02c and push them to the SQL database.



# Data Back up and Auditing
There are four scripts in the 05_backup_audit directory for data back up and auditing. These scripts will back up all data to acacia, as well as generate TSV files that show the size of each directory before and after backup to ensure the backup has completed properly.

In order run:

    00_check_files.sh - This script will check that you have all the files for every sample. Copy the tsv over to excel for easier visualisation. This script can be used at other times throughout the pipeline to track files.

    01_Data_audit_local.sh - This will calculate the number of files and the size of each samples directory for the total workflow output in the output directory.

    02_final-genome-backup.sh - This script will move the whole output directory over to acacia. NOTE: this moves everything, not copy, so no files will be left on your scratch.

    03_Data_audit_acacia.sh - This script will caculate the number of files and the size of each samples directory on Acacia for comparison with the previous calculations. 

 








# Alternative Genome QC workflow
The workflow can be ran as a series of scripts farmed out across a run (project-directory)
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
