#!/bin/bash 
#SBATCH --account=pawsey0812
#SBATCH --job-name=downloadfrombasespace
#SBATCH --partition=copy
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=2
#SBATCH --time=48:00:00
#SBATCH --export=NONE
#SBATCH --output=%x-%j.out  
#SBATCH --error=%x-%j.err

#edit the $RUN variable for the specified run you would like to download and the job can be submitted using sbatch

RUN=NOVA_230419_AD
RUNDIR=/scratch/pawsey0812/tpeirce/draftgenomes/download
RUNID=$(bs list run | grep $RUN | awk '{print $4}')
mkdir -p $RUNDIR/$RUN


#this creates the list of all the lanes for downloading
bs list dataset --input-run $RUNID | awk '{print $2;}' > $RUN.prefix.txt 
sed -i '1,3d' $RUN.prefix.txt


#these three lines create the text file to be used in the wgs-cat script for concatinating the lanes
bs list dataset --input-run $RUNID | awk '{print $2;}'| awk -F_ '{print $1}' > $RUN.forcat.prefix.txt
sed -i '1,3d' $RUN.forcat.prefix.txt
sort -u -o $RUN.forcat.prefix.txt $RUN.forcat.prefix.txt


for PREFIX in $(cat $RUN.prefix.txt); do
ID=$(bs list dataset --input-run $RUNID | grep $PREFIX | awk '{print $4;}')
echo $PREFIX $ID ">>" $RUNDIR/$RUN/$PREFIX
bs download dataset ---input-run $RUNID -i $ID -o $RUNDIR/$RUN/$PREFIX
done
