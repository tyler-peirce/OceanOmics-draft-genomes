#!/usr/bin/env nextflow
nextflow.enable.dsl = 2

/*
 * pipeline input parameters
 */

params.projectDir =""  // should be the path do the  $RUNDIR

// Define the pattern to match sample directories
samplePattern = params.projectDir + "/*"
// Define the pattern to match assembly files
assemblyPattern = samplePattern + "/assemblies/genome/*.fna"
// Call the assemblies using the assembly pattern
params.assembly = file(assemblyPattern)
//params.fastq = file(fastqPattern)


params.sample_ID = file("$projectDir").getName()
params.fastq="$params.projectDir/*/fastp/*.{R1,R2}.fastq.gz"
params.meryldb ="$params.projectDir/*/kmers/*.meryl"
params.scriptPath = "${baseDir}/bin/busco2tsv.R"
params.lineage = "actinopterygii_odb10"

 



process busco_acti {
//debug true
    publishDir "$params.projectDir/${assembly.simpleName}/assemblies/genome/busco_acti", mode:'copy'


    input:
    tuple val(assembly_id), path(assembly)

    output:
        path "${assembly}.busco.Acti.short_summary.txt", emit: summary_txt
        path "${assembly}.busco.Acti.short_summary.json", emit: summary_json
        tuple val(assembly_id), path("${assembly}.busco.Acti.full_table.tsv"), emit: busco_acti_tsv
        path "${assembly}.busco.Acti.busco_sequences.tar.gz", emit: sequence_tar_gz
        path "${assembly}.busco.Acti.busco_sequences.tar.gz.md5", emit: md5
        path "${assembly}.busco.Acti.missing_busco_list.tsv", emit: missing_tsv
        path "${assembly}.busco.Acti.logs" , emit: logs

    script:
    """
    busco -i ${assembly} -o ${assembly}.busco.Acti -l actinopterygii_odb10 -m genome -c 8 -f
    mv ${assembly}.busco.Acti/run_actinopterygii_odb10/short_summary.txt ${assembly}.busco.Acti.short_summary.txt
    mv ${assembly}.busco.Acti/run_actinopterygii_odb10/short_summary.json ${assembly}.busco.Acti.short_summary.json
    mv ${assembly}.busco.Acti/run_actinopterygii_odb10/full_table.tsv ${assembly}.busco.Acti.full_table.tsv
    mv ${assembly}.busco.Acti/run_actinopterygii_odb10/busco_sequences ${assembly}.busco.Acti.busco_sequences
    mv ${assembly}.busco.Acti/run_actinopterygii_odb10/missing_busco_list.tsv ${assembly}.busco.Acti.missing_busco_list.tsv
    mv ${assembly}.busco.Acti/logs ${assembly}.busco.Acti.logs

    tar -czvf ${assembly}.busco.Acti.busco_sequences.tar.gz ${assembly}.busco.Acti.busco_sequences
    md5sum ${assembly}.busco.Acti.busco_sequences.tar.gz > ${assembly}.busco.Acti.busco_sequences.tar.gz.md5 &&  rm -rf ${assembly}.busco.Acti.busco_sequences
    
    """

}

process compile_busco_acti {
//debug true
        publishDir "$params.projectDir/${assembly.simpleName}/assemblies/genome/busco_acti", mode:'copy'

        input: 
        file assembly

        output:
        file ("${assembly}.tsv") 

    """
    #!/usr/bin/env bash
    Rscript ${params.scriptPath} "${assembly}"

    """

}

process busco_vert {
debug true
    publishDir "", mode:'copy'


    input:
    tuple val(assembly_id), path(assembly)

    output:
        path "${assembly}.busco.vert.short_summary.txt"
        path "${assembly}.busco.vert.short_summary.json"
        tuple val(assembly_id), path("${assembly}.busco.vert.full_table.tsv"), emit: busco_vert_tsv
        path "${assembly}.busco.vert.busco_sequences"
        path "${assembly}.busco.vert.missing_busco_list.tsv"
        path "${assembly}.busco.vert.logs" 

    script: 
    """
    busco -i ${assembly} -o ${assembly}.busco.vert -l vertebrata_odb10 -m genome -c 8
    mv ${assembly}.busco.vert/run_vertebrata_odb10/short_summary.txt ${assembly}.busco.vert.short_summary.txt
    mv ${assembly}.busco.vert/run_vertebrata_odb10/short_summary.json ${assembly}.busco.vert.short_summary.json
    mv ${assembly}.busco.vert/run_vertebrata_odb10/full_table.tsv ${assembly}.busco.vert.full_table.tsv
    mv ${assembly}.busco.vert/run_vertebrata_odb10/busco_sequences ${assembly}.busco.vert.busco_sequences
    mv ${assembly}.busco.vert/run_vertebrata_odb10/missing_busco_list.tsv ${assembly}.busco.vert.missing_busco_list.tsv
    mv ${assembly}.busco.vert/logs ${assembly}.busco.vert.logs

    tar -czvf ${assembly}.busco.Acti/run_vertebrata_odb10/busco_sequences.tar.gz ${assembly}.busco.Acti/run_vertebrata_odb10/busco_sequences
    md5sum ${assembly}.busco.Acti/run_vertebrata_odb10/busco_sequences.tar.gz > ${assembly}.busco.Acti/run_vertebrata_odb10/busco_sequences.tar.gz.md5 &&  rm -rf ${assembly}.busco.Acti/run_vertebrata_odb10/busco_sequences

    """

}

process compile_busco_vert {
debug true
        publishDir "", mode:'copy'

        input: 
        file assembly_id

        output:
        file ("${assembly_id}.tsv") 

    """
    #!/usr/bin/env bash
    Rscript ${params.scriptPath} "${assembly_id}"

    """

}


process bwa_align {
//debug true

    publishDir "$params.projectDir/${assembly.simpleName}/assemblies/genome/bwa", mode:'copy'

        input:
        tuple val(sample_id), path(reads), val(assembly_id), path(assembly)

        output:
        tuple val(assembly_id), path("${assembly_id}.sorted.bam"), emit: sorted_bam
        path ("${assembly_id}-sn_results.tsv")


    script:
    """ 
    bwa index ${assembly} 

    bwa mem -t 24 ${assembly} ${reads[0]} ${reads[1]} > ${assembly_id}.aligned.sam
    samtools view -S -b ${assembly_id}.aligned.sam | samtools sort -o ${assembly_id}.sorted.bam -
    samtools index ${assembly_id}.sorted.bam

    wait
    
    samtools stats ${assembly_id}.sorted.bam | grep "^SN" | cut -f 2- > ${assembly_id}-sn_results.tsv


    """

}


process merqury {
//debug true
    publishDir "$params.projectDir/${assembly.simpleName}/kmers", mode:'copy'


    input:
    tuple val(assembly_id), path(meryldb), path(assembly)

    output:
    path "*.completeness.stats"
    path "*.png"
    path "*.qv"

    script:

    """
    
   export MERQURY=/usr/local/share/merqury
    \$MERQURY/merqury.sh ${meryldb} ${assembly} '${assembly.baseName}.merqury'

    """

}

process depthsizer {
//debug true
publishDir "$params.projectDir/${assembly.simpleName}/assemblies/genome/depthsizer", mode:'copy'

//For some reason nextflow thinks normal depthsizer output is errerous so had to force exit code as 0
        input:
        tuple val(assembly_id), path (assembly)
        tuple val (sample_id), path(reads)
        tuple val(assembly_id), file ("${assembly}.busco.Acti.full_table.tsv")
        tuple val(assembly_id), file ("${assembly_id}.sorted.bam")

        output:
        path '*.fastmp.scdepth'
        path '*.gensize.tdt'
        path '*.depthsizer.fulltable.tsv'
        path '*.depthsizer.busco.dupcnv.tsv'

        script:
        """
        python /opt/depthsizer_code/scripts/depthsizer.py -seqin ${assembly} -bam '${sample_id}.sorted.bam' -busco '${assembly}.busco.Acti.full_table.tsv' -reads ${reads[0]} ${reads[1]} -basefile=${assembly}.depthsizer -forks 40 i=-1 v=0 > /dev/null 2>&1 || (exit 0)


        if [ -e *.fastmp.scdepth ] && [ -e *.gensize.tdt ] && [ -e *.depthsizer.fulltable.tsv ] && [ -e *.depthsizer.busco.dupcnv.tsv ]; then
            rm -rf tmpdir
            exit 0  
        else
            exit 1  
        fi

        """
}


workflow {


//#################################################################################
//##### BUSCO workflow actinopterygii_odb10 ###### 

    busco_acti_assemblies_ch = Channel.fromPath(params.assembly)
    .map { it -> [it[4], it] }
    .ifEmpty { error "No assembly file found at: ${params.assembly}" }
   //.view()
    
    busco_acti_ch = busco_acti(busco_acti_assemblies_ch)  //if you are calling the bucos_db as part of the container use this

    compile_busco_acti(busco_acti_ch[1])

//######################################################################################

//##### BUSCO workflow vertebrate_odb10 ###### 


    //busco_vert_assemblies_ch = Channel
    //    .fromPath(params.assembly)
        //.view()
    
    //busco_vert_ch = busco_vert(busco_vert_assemblies_ch)

    //compile_busco_vert(busco_vert_ch[1])
//#####################################################################################


// #### BWA workflows #### 
    ref_ch = Channel.fromPath(params.assembly, checkIfExists: true)
           .map { it -> [it[4], it] }  //update the matching key per your file path and direcotry structure
             //  .view ()

fastq_ch = Channel.fromFilePairs(params.fastq, checkIfExists: true)
   .map { pair ->
      def key = pair[0].tokenize('.').get(0) // Extract the part of the filename before the first full stop
       [key, pair[1]] // Create a new pair with the modified key and the original value
   }
   // .view()
   //  Join the channels based on the matching keys
    join_ch = fastq_ch.join(ref_ch, by: 2)
    //          .view()


 bwa_align(join_ch)
  //  .view()


//##########################################################################################
// #### merqury workflow ####

   assembly_ch = Channel.fromPath(params.assembly, checkIfExists: true)
        .map { it -> [it[4], it] }
    //.view()    


    meryldb_ch = Channel.fromPath(params.meryldb, type: 'dir', checkIfExists: true)
        .map { it -> [it[4], it] }      //update the matching key per your file path and direcotry structure
       // .view()

  combine_ch = meryldb_ch.join(assembly_ch)
 //       .view()

   merqury(combine_ch)
   // .view()

//##########################################################################################
// #### Depthsizer workflow  use the emit busco_table, sorted BAM file, assembly and reads files for input

// Define channels for inputs for assembly
     depth_assembly_ch = Channel.fromPath(params.assembly, checkIfExists: true)
          .map { it -> [it[4], it] }  //update the matching key per your file path and direcotry structure
        //  .view ()

    // channel for reads 
 depth_fastq_ch = Channel.fromFilePairs(params.fastq, checkIfExists: true)
    .map { pair ->
        def key = pair[0].tokenize('.').get(0) // Extract the part of the filename before the first full stop
       [key, pair[1]] // Create a new pair with the modified key and the original value
    }
    //.view()

// call busco_full_table
    busco_acti.out.busco_acti_tsv
    //.view()

// call sorted bam file
    bwa_align.out.sorted_bam
    //.view()


    // depthsizer process
  depthsizer(depth_assembly_ch,depth_fastq_ch, busco_acti.out.busco_acti_tsv, bwa_align.out.sorted_bam)


}
