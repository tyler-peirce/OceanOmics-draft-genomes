#!/usr/bin/env nextflow
nextflow.enable.dsl = 2

/*
 * Function to read the config file and extract variables
 */
def readConfigFile(configFile) {
    def config = [:]
    new File(configFile).eachLine { line ->
        if (!line.startsWith('#') && !line.startsWith('.') && !line.startsWith('module') && line.contains('=')) {
            def (key, value) = line.split('=')
            value = value.replaceAll('~', System.getProperty('user.home')) // Handle home directory shortcut
            config[key.trim()] = value.trim()
        }
    }
    
    // Evaluate variable references
    config.each { key, value ->
        config[key] = evaluateExpression(value, config)
    }
    
    return config
}

def evaluateExpression(value, config) {
    // Handle variable substitution
    def result = value
    config.each { key, val ->
        result = result.replace('$' + key, val)
    }
    return result
}

// Load the config file
def configFile = '../configfile.txt'
def config = readConfigFile(configFile)

// Assign config values to params
params.RUN = config['RUN']
params.rundir = config['rundir']
params.pooled = config['pooled']
params.results = config['results']

/*
 * pipeline input parameters
 */

params.projectDir = "$params.rundir"
params.reads="$params.projectDir/*/fastp/*.{R1,R2}.fastq.gz"

process meryl {
    publishDir "$params.projectDir/${og_num}/kmers", mode:'copy'

    input:
    tuple val(og_num), val(sample_id), path(reads)

    output: 
    tuple val(og_num), val(sample_id), path ("${sample_id}.meryl.hist"), emit: hist
    tuple val(og_num), val(sample_id), path("${sample_id}.meryl")

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

   publishDir "$params.projectDir/${og_num}/kmers", mode:'copy'

   input:
   tuple val(og_num), val(sample_id), path ("${sample_id}.meryl.hist")
    

    output:
    path "${sample_id}"


    script:
    """ 
    genomescope.R -i '${sample_id}.meryl.hist' -k 21 -o '${sample_id}' -n '${sample_id}-genomescope'  -m 1000

    """
}

//process megahit {

//   publishDir "$params.projectDir/${og_num}/assemblies/genome", mode:'copy'

//    input:
//    tuple val(og_num), val(sample_id), path(reads)

//    output:
//    tuple val(sample_id), path("${sample_id}.v129mh.fasta")

//    script:
    
//    """
//    megahit -1 ${reads[0]} -2 ${reads[1]} -m 200000000000 -t 24 -o ./mh${sample_id} --continue
//    mv ./mh${sample_id}/final.contigs.fa ${sample_id}.v129mh.fasta
//   """

//}

workflow {

    read_pairs_kmer_ch = Channel
        .fromFilePairs(params.reads, checkIfExists: true)
        .map { 
            def sample = it[0].tokenize('.').get(0)
            return tuple(sample, it[0], it[1]) 
        }
        .view()

  

    meryl_ch = meryl(read_pairs_kmer_ch)
    
    genomescope(meryl.out.hist)

  //megahit_ch = megahit(read_pairs_kmer_ch) 

}
