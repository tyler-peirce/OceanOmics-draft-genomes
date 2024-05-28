#!/usr/bin/env nextflow
nextflow.enable.dsl = 2

/*
 * pipeline input parameters
 */
params.projectDir = "[path to run dir]"
params.reads = "[path to raw reads]/*.{R1,R2}.fq.gz"
params.multiqc = "$params.$projectDir/add RUN ID/multiqc"
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

    publishDir "$params.projectDir/${og_num}/fastp", mode: 'symlink'
 
    input:
    tuple val(og_num), val(sample_id), path(reads) 

    output:
    tuple val(sample_id), 
    path("${sample_id}.R1.fastq.gz")
    path("${sample_id}.R2.fastq.gz")
    tuple val(og_num), path("${sample_id}.fastp.json"),  emit: fastp_json
    path("${sample_id}.fastp.html")
   

    script:
    """
    fastp --in1 ${reads[0]} --out1 ${sample_id}.R1.fastq.gz --in2 ${reads[1]} --out2 ${sample_id}.R2.fastq.gz --verbose --max_len1 150 --max_len2 150 --length_required 100  --json '${sample_id}.fastp.json' --html '${sample_id}.fastp.html' --report_title="${sample_id} fastp" --thread 16 2>&1 | tee ${sample_id}.fastp.log


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

    publishDir params.multiqc, mode:'copy'

  input:
   path '*'
  


   output:
   path 'multiqc_report.html'

  script:
    """
    multiqc .
    """
}


workflow {

    read_pairs_ch = Channel
        .fromFilePairs(params.reads, checkIfExists: true)
        .map { 
            def sample = it[0].tokenize('.').get(0)
            return tuple(sample, it[0], it[1]) 
        }
        .view()

   fastqc_ch = fastqc(read_pairs_ch)
    fastp_ch = fastp(read_pairs_ch)
    
   compile(fastp.out.fastp_json).view()
                
 
   
   multiqc(fastqc_ch.mix(fastp_ch[1]).collect())// the collect enables the data to be pushed through as a collection, so it will be 1 task, if there is no collect these will be run as separate tasks 


}
