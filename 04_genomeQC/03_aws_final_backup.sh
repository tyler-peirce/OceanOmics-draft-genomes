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
#SBATCH --output=%x-%j.out #SBATCH --error=%x-%j.err


. ../configfile.txt

## pull out the final fasta files and the filtered and trimmed reads to upload to AWS

for i in "$rundir"/OG*; do
    if [ -d "$i" ]; then  # Check if the item in $rundir is a directory
        SAMPLE=$(basename "$i")
        fasta="$rundir/$SAMPLE/assemblies/genome/*.fna"
        reads="$rundir/$SAMPLE/fastp/*.fastq.gz"
        wrkdir=$(dirname "$(dirname "$i")")
        dir=$wrkdir/AWS_backup
        mkdir -p $dir
        newdir=$dir/$SAMPLE
        mkdir -p $newdir
                
        #(this will put the *.fna & reads into directorys with their OG numbers for storage)
        cp $fasta $newdir
        cp $reads $newdir

    fi
done
 

wait 

# you can use either rclone or aws to copy the files over. Hash out which ever one you dont want to use.
rclone copy $dir/ s3://oceanomics/OceanGenomes/analysed-data/draft-genomes/ --checksum --progress
#aws s3 cp --recursive $dir s3://oceanomics/OceanGenomes/analysed-data/draft-genomes/