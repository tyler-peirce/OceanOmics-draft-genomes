#!/bin/bash
. ../../configfile.txt

# Download the taxonomy data if you dont already have it.
#    wget ftp://ftp.ncbi.nih.gov/pub/taxonomy/taxdump.tar.gz
#    wget ftp://ftp.ncbi.nlm.nih.gov/blast/db/taxdb.tar.gz

    #unzip into the current directory
#    tar -xvf taxdump.tar.gz 
#    tar -xvf taxdb.tar.gz
    #copy the files over to the specified location
#    cp names.dmp nodes.dmp delnodes.dmp merged.dmp /home/tpeirce/.taxonkit


# Create a list of the nominal species for the samples
# Copy the OG number and nominal species ids from the lab database metadata and create a file called nomspecies.txt
file="$scripts/03_decontamination/00_species_check/nomspecies.txt"


for SAMP in $rundir/OG*; do    
    OG=$(basename $SAMP)
    
    echo "SAMP = $SAMP"
    echo "OG = $OG"
    
    species=$(cat $file | grep -w -m 1 "$OG" | awk -F '\t' '{print $2}')
    
    echo "$species"

    TAXONKIT="singularity run $SING/taxonkit:0.15.1.sif taxonkit"
    lineage=$(echo $species | $TAXONKIT name2taxid | awk -F '\t' '{print $2}' | $TAXONKIT lineage)

    # Creating a new variable to determine which db to use, either the vertebrate or actinopterygii
    buscodb="vertebrate"
    # Check if lineage is empty or does not contain "actinopterygii"
    if [ -z "$lineage" ] || echo "$lineage" | grep -qi "actinopterygii"; then
        buscodb="actinopterygii"
    fi


    echo -e "$OG\t$buscodb\t$species\t$lineage" >> $results/taxon.txt

done 


## You need to check the taxon for busco file to make sure that there is buscodb value of either "actinopterygii" or "vertebrate". 
## You also need to check if there is a taxon id in the 4th column. 
## If there is no taxon id number you need to put 7898 if it is an actinopterygii
## Or 7777 for cartiuloaginous fish (fins and rays)
## if its some other type of vertebrate you need to find the taxon id for its family/order
## the taxon ids are used for decontamination steps and the bsucodb value is used for the 04_genomeQC nextflow pipeline.