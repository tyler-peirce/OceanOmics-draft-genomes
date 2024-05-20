#!/bin/bash --login

#---------------
#Requested resources:
#SBATCH --account=pawsey0812
#SBATCH --job-name=aws_final_backup
#SBATCH --partition=work
#SBATCH --ntasks=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --time=14:00:00
#SBATCH --mem=10G 
#SBATCH --export=ALL
#SBATCH --output=%x-%j.out
#SBATCH --error=%x-%j.err
#SBATCH --mail-type=BEGIN,END
#SBATCH --mail-user=



## pull out the final fasta files and the filtered and trimmed reads to upload to AWS

RUNDIR= [path to the $RUN ]
DATE= [ date of the assembly

for i in "$RUNDIR"/OG*; do
    if [ -d "$i" ]; then  # Check if the item in $RUNDIR is a directory
        SAMPLE=$(basename "$i")
        fasta="$RUNDIR/$SAMPLE/assemblies/genome/*.fna"
        reads="$RUNDIR/$SAMPLE/fastp/*.fastq.gz"
        mkdir -P [create a directory to move the files to for backup]
        newdir= $path-to-direcotry-you-just-created/$SAMPLE/    [this will put the *.fna & reads into directorys with their OG numbers for storage)

        cp $fasta $newdir
       cp $reads $newdir

    fi
done
 

 #wait


aws s3 cp --recursive [path-to-backup-directory]/ s3://oceanomics/OceanGenomes/analysed-data/draft-genomes/
