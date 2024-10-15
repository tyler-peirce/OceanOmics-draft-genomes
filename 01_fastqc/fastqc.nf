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
params.WRKDIR = config['WRKDIR']
params.DATE = config['DATE']


/*
 * pipeline input parameters
 */
params.projectDir = params.rundir
params.reads = "${params.pooled}/*.{R1,R2}.fq.gz"
params.multiqc = "${params.WRKDIR}/${params.DATE}_results"
params.scriptPath = "${baseDir}/bin/fastp-json2tsv.R"


process fastqc {
    publishDir "$params.projectDir/${og_num}/fastp/fastqc" , mode:'copy'

    input:
    tuple val(og_num), val(sample_id), path(reads)

    output:
    path "fastqc_${sample_id}_logs"

    script:
    """
    mkdir fastqc_${sample_id}_logs
    fastqc ${reads[0]} ${reads[1]} -o fastqc_${sample_id}_logs
    """
}

 process fastp {

    publishDir "$params.projectDir/${og_num}/fastp", mode: 'copy'
 
    input:
    tuple val(og_num), path(reads), val(new_sample_id), val(sample_id)

    output:
    tuple val(new_sample_id), 
    path("${new_sample_id}.R1.fastq.gz")
    path("${new_sample_id}.R2.fastq.gz")
    tuple val(og_num), path("${sample_id}.fastp.json"),  emit: fastp_json
    path("${new_sample_id}.fastp.html")
   

    script:


    """
    fastp --in1 ${reads[0]} --out1 ${new_sample_id}.R1.fastq.gz --in2 ${reads[1]} --out2 ${new_sample_id}.R2.fastq.gz --verbose --max_len1 150 --max_len2 150 --length_required 100 --json '${sample_id}.fastp.json' --html '${new_sample_id}.fastp.html' --report_title="${new_sample_id} fastp" --thread 16 2>&1 | tee ${new_sample_id}.fastp.log

    """
}

process compile {

        publishDir "$params.projectDir/${og_num}/fastp", mode: 'copy'

        input: 
        tuple val(og_num), file (sample_id)

        output:
        file ("${sample_id}.tsv") 

    """
     #!/usr/bin/env bash
    Rscript ${params.scriptPath} "${sample_id}"

    """

}


process multiqc {

    publishDir "$params.multiqc", mode:'copy'

  input:
   path '*'
  


   output:
   path "${params.RUN}.multiqc_report.html"

// add in a move command such as mv multiqc_report.html "${params.RUN}.multiqc_report.html" into this scripts part and test
  script:
    """
    multiqc --filename ${params.RUN}.multiqc_report.html .
    """
}


workflow {

    read_pairs_ch = Channel
        .fromFilePairs(params.reads, checkIfExists: true)
        .map { 
            def sample = it[0].tokenize('.').get(0)
            return tuple(sample, it[0], it[1]) 
        }
        


   fastqc_ch = fastqc(read_pairs_ch)

       fastp_input_ch = read_pairs_ch.map { og_num, sample_id, reads ->
        def name = sample_id.tokenize(".")
        def parts = sample_id.tokenize('_')
        def new_sample_id = "${name[0]}.${name[1]}.${parts[1]}"
        return tuple(og_num, reads, new_sample_id, sample_id )
    }.view()
    
    fastp_ch= fastp(fastp_input_ch)
    
   compile(fastp.out.fastp_json)
                
 
   
   multiqc(fastqc_ch.mix(fastp_ch[1]).collect()).view()  // the collect enables the data to be pushed through as a collection, so it will be 1 task, if there is no collect these will be run as separate tasks 


}
