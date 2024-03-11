#For depthsizer to run you will need to provide the paths to the following outputs
#R1 &R2 fastq files. 
#sorted BAM bam from BWA
#the final decontaminated assembly file 
#the BUSCO full table tsv file 
#To ensure all the results remained contained in the correct directory, you will need to submit the script from within the directory (as shown in the loop below) 
RUNDIR=

for i in "$RUNDIR"/*; do
    if [ -d "$i" ]; then  # Check if the item in $RUNDIR is a directory
        SAMPLE=$(basename "$i")
        mkdir -p "$RUNDIR/$SAMPLE/assemblies/genome/depthsizer"
        DEPTHSIZER_DIR="$RUNDIR/$SAMPLE/assemblies/genome/depthsizer"
        SCRIPTS= 
        RUNDIR=
        cd $DEPTHSIZER_DIR
        R1=
        R2=
        BAMFILE=
        BUSCOTSV=
        FASTA=
        OUTNAME="$SAMPLE.ilmn.depthsizer

        sbatch $SCRIPTS/depthsizer.sh "$SAMPLE" "$RUNDIR" "$SCRIPTS" "$R1" "$R2" "$BAMFILE" "$BUSCOTSV" "$FASTA" "$OUTNAME"
    fi
done
