#!/bin/bash --login

#---------------
#Requested resources:
#SBATCH --account=pawsey0812
#SBATCH --job-name=aws_final_backup
#SBATCH --partition=work
#SBATCH --ntasks=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=6
#SBATCH --time=14:00:00
#SBATCH --mem=10G 
#SBATCH --export=ALL
#SBATCH --output=%x-%j.out
#SBATCH --error=%x-%j.err



## pull out the final fasta files and the filtered and trimmed reads to upload to AWS

RUNDIR=[run directory]
DATE=[date of sequencing run]

for i in "$RUNDIR"/OG*; do
    if [ -d "$i" ]; then  # Check if the item in $RUNDIR is a directory
        SAMPLE=$(basename "$i")
        fasta="$RUNDIR/$SAMPLE/assemblies/genome/*.fna"
        reads="$RUNDIR/$SAMPLE/fastp/*.fastq.gz"
        mkdir -p [Create new directory for backup of final fasta file and reads to AWS for genbank upload]# eg /scratch/pawsey0812/lhuet/NOVA_230324_AD_BACKUP
        newdir=[path to directory you just creadted]/$SAMPLE/

        cp $fasta $newdir
       cp $reads $newdir

    fi
done
 

 wait


aws s3 cp --recursive [PATH TO BACK UP DIRECTORY] s3://oceanomics/OceanGenomes/analysed-data/draft-genomes/
