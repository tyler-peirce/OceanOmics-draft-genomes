#!/usr/bin/env nextflow
nextflow.enable.dsl = 2

/*
 * pipeline input parameters
 */

params.reads = 

process meryl {
    publishDir "/scratch/pawseyACCOUNT/username/run-name/${sample_id}/kmers", mode:'copy'

    input:
    tuple val(sample_id), path(reads)

    output: 
    tuple val(sample_id), path ("${sample_id}.meryl.hist"), emit: hist
    tuple val(sample_id), path("${sample_id}.meryl")

    script:
    
    """
    meryl k=21 count output '${reads[0].baseName}.meryl' ${reads[0]}
    meryl k=21 count output '${reads[1].baseName}.meryl' ${reads[1]}
    meryl union-sum output '${sample_id}.meryl' '${reads[0].baseName}.meryl' '${reads[1].baseName}.meryl'
    meryl histogram '${sample_id}.meryl' > '${sample_id}.meryl.hist'

    
    """
}

process genomescope { 
    tag "genomescope on $sample_id"

   publishDir "/scratch/pawseyACCOUNT/username/run-name/${sample_id}/kmers", mode:'copy'

   input:
   tuple val(sample_id), path ("${sample_id}.meryl.hist")
    

    output:
    path "${sample_id}"


    script:
    """ 
    genomescope.R -i '${sample_id}.meryl.hist' -k 21 -o '${sample_id}' -n '${sample_id}-genomescope'  -m 1000

    """
}

process megahit {

    publishDir "/scratch/pawseyACCOUNT/username/run-name/${sample_id}/assemblies/genome", mode:'copy'

    input:
    tuple val(sample_id), path(reads)

    output:
    tuple val(sample_id), path("${sample_id}.v129mh.fasta")

    script:
    
    """
    megahit -1 ${reads[0]} -2 ${reads[1]} -m 200000000000 -t 24 -o ./mh${sample_id}
    mv ./mh${sample_id}/final.contigs.fa ${sample_id}.v129mh.fasta
    """

}

workflow {

    read_pairs_kmer_ch = Channel
        .fromFilePairs(params.reads, checkIfExists: true)

    meryl_ch = meryl(read_pairs_kmer_ch)
    
    genomescope(meryl.out.hist)

   read_pairs_megahit_ch = Channel
        .fromFilePairs(params.reads, checkIfExists: true)
    
    megahit_ch = megahit(read_pairs_megahit_ch) 

}
