#!/bin/bash
. ../configfile.txt
# This is a script for pooling the sequenicng lanes together and keeping OG numbers 


VERSION=v0.3.0


# Usage: wgs-cat.sh $RUN $SAMPLE
SAMPLE=$2


if [ "--version" = "$RUN" ]; then
  echo $VERSION
  exit 1
fi


if [ "--help" = "$RUN" ] || [ -z "$RUN" ] || [ -z "$SAMPLE" ]; then
  echo "Usage: 04a_wgs-cat.sh \$RUN \$SAMPLE"
  exit 1
fi


if [ -z "$SAMPLE" ]
then
  exit 1
fi


echo "Processing sample" $SAMPLE "from" $RUN


# Setup the main system settings
MEM=180   # Max memory (GB) for repair.sh


# Setup run directory details
POOLDIR=$pooled
QCDIR=$POOLDIR/qc 
mkdir -p $QCDIR 
echo $QCDIR


## Defining the new names for the samples 
R1=$POOLDIR/$SAMPLE.ilmn.$RUN.R1.fq.gz
R2=$POOLDIR/$SAMPLE.ilmn.$RUN.R2.fq.gz

# Concatenate the raw fastq files for filtering
ls -l $download/$SAMPLE*/*R1*gz | tee -a $QCDIR/$SAMPLE.paircheck.log


cat $download/$SAMPLE*/*R1*gz > $R1 && echo "cat R1 completed (exit:$?)" | tee -a $QCDIR/$SAMPLE.paircheck.log
cat $download/$SAMPLE*/*R2*gz > $R2 && echo "cat R2 completed (exit:$?)" | tee -a $QCDIR/$SAMPLE.paircheck.log
ls -l $R1 $R2 | tee -a $QCDIR/$SAMPLE.paircheck.log
singularity run $SING/bbmap:39.01.sif repair.sh -Xmx${MEM}g in=$R1 in2=$R2 2>&1 | grep ':' | tee -a $QCDIR/$SAMPLE.paircheck.log

wait

# Calculate MD5 checksums for the final FASTQ files and print them
echo "MD5 checksum for $R1:"
md5sum $R1

echo "MD5 checksum for $R2:"
md5sum $R2
