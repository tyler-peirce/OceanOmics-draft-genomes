#!/bin/bash --login

#SBATCH --account=pawsey0812
#SBATCH --job-name=final-genome-upload
#SBATCH --partition=long
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --time=60:00:00
#SBATCH --export=NONE
#SBATCH --mail-type=BEGIN,END
#SBATCH --mail-user=
#-----------------
#Loading the required modules

. ../configfile.txt

# Zip the meryl database before backing up.
for i in  "$rundir"/OG31; do
    if [ -d "$i" ]; then  # Check if the item in $rundir is a directory
        OG=$(basename "$i")
        MERYL=$i/kmers/$OG.ilmn.$DATE.meryl
        
        tar -czvf $MERYL.tar.gz -C $i/kmers/ $OG.ilmn.$DATE.meryl
        
        wait
        
        rm -rf $MERYL
    fi
done

wait

rclone move $rundir pawsey0812:oceanomics-genomes/genomes.v2/  --checksum -P
