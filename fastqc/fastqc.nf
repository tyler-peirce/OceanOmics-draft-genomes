#!/usr/bin/env nextflow
nextflow.enable.dsl = 2

/*
 * pipeline input parameters
 */
params.reads = "/scratch/pawseyACCOUNT/$user/download/run/*.{R1,R2}.fq.gz"
params.multiqc = "/scratch/pawseyACCOUNT/$user/run/multiqc"


process fastqc {
    publishDir "/scratch/pawseyACCOUNT/$user/run/${sample_id}/fastp/fastqc" , mode:'copy'

    input:
    tuple val(sample_id), path(reads)

    output:
    path "fastqc_${sample_id}_logs"

    script:
    """
    mkdir fastqc_${sample_id}_logs
    fastqc ${reads[0]} ${reads[1]} -o fastqc_${sample_id}_logs
    """
}

 process fastp {

    publishDir "/scratch/pawseyACCOUNT/$user/run/${sample_id}/fastp", mode: 'copy'
 
    input:
    tuple val(sample_id), path(reads) 

    output:
    tuple val(sample_id), 
    path("${sample_id}.R1.fastq.gz")
    path("${sample_id}.R2.fastq.gz")
    path("${sample_id}.fastp.json") 
    path("${sample_id}.fastp.html")
   

    script:
    """
    fastp --in1 ${reads[0]} --out1 ${sample_id}.R1.fastq.gz --in2 ${reads[1]} --out2 ${sample_id}.R2.fastq.gz --verbose --max_len1 150 --max_len2 150 --length_required 100  --json '${sample_id}.fastp.json' --html '${sample_id}.fastp.html' --report_title="${sample_id} fastp" --thread 16 2>&1 | tee ${sample_id}.fastp.log


    """
}

process compile {

        publishDir "/scratch/pawseyACCOUNT/$user/run/${sample_id}/fastp", mode: 'copy'

        input: 
        file sample_id

        output:
        file ("${sample_id}.tsv") 

    """
     #!/usr/bin/env bash
    Rscript /scratch/pawseyACCOUNT/$user/nextflow-wgs/V2/fastqc/bin/fastp-json2tsv.R "${sample_id}"

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

    read_pairs_fastp_ch = Channel
        .fromFilePairs(params.reads, checkIfExists: true)

    fastqc_ch = fastqc(read_pairs_ch)
    fastp_ch = fastp(read_pairs_fastp_ch)
    
    compile(fastp_ch[1])
                
 
   
    multiqc(fastqc_ch.mix(fastp_ch[1]).collect())// the collect enables the data to be pushed through as a collection, so it will be 1 task, if there is no collect these will be run as separate tasks 


}

workflow.onComplete {
    log.info ( workflow.success ? "\nDone! Open the following report in your browser --> $params.multiqc/multiqc_report.html\n" : "Oops .. something went wrong" )
}
