#!/usr/bin/env nextflow
nextflow.enable.dsl = 2

/*
 * pipeline input parameters
 */


params.assembly="/scratch/PAWSEYACCOUNT/$USER/RUN/OG*/assemblies/genome/*.fna"
params.reads="/scratch/PAWSEYACCOUNT/$USER/RUN/OG*/fastp/*.{R1,R2}.fq.gz"
params.meryldb ="/scratch/PAWSEYACCOUNT/$USER/RUN/OG*/kmers/*.meryl"
params.lineage = "/software/projects/PAWSEYACCOUNT/singularity/busco_db/actinopterygii_odb10"



process busco_acti {

    publishDir "", mode:'copy'


    input:
    path(assembly)

    output:
        path "${assembly}.busco.Acti.short_summary.txt"
        path "${assembly}.busco.Acti.short_summary.json"
        path "${assembly}.busco.Acti.full_table.tsv"
        path "${assembly}.busco.Acti.busco_sequences.tar.gz"
        path "${assembly}.busco.Acti.busco_sequences.tar.gz.md5"
        path "${assembly}.busco.Acti.missing_busco_list.tsv"
        path "${assembly}.busco.Acti.logs" 

    script:

    """
    busco -i ${assembly} -o ${assembly}.busco.Acti -l actinopterygii_odb10 -m genome -c 8
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

        publishDir "", mode:'copy'

        input: 
        file assembly_id

        output:
        file ("${assembly_id}.tsv") 

    """
    #!/usr/bin/env bash
    Rscript /path-to/busco2tsv.R "${assembly_id}"

    """

}

process busco_vert {

    publishDir "", mode:'copy'


    input:
    path(assembly)

    output:
        path "${assembly}.busco.vert.short_summary.txt"
        path "${assembly}.busco.vert.short_summary.json"
        path "${assembly}.busco.vert.full_table.tsv"
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

        publishDir "", mode:'copy'

        input: 
        file assembly_id

        output:
        file ("${assembly_id}.tsv") 

    """
    #!/usr/bin/env bash
    Rscript /scratch/PAWSEYACCOUNT/$USER/scripts/busco-nf/bin/busco2tsv.R "${assembly_id}"

    """

}


process bwa_align {


    publishDir "", mode:'copy'

        input:
        tuple val(sample_id), path(reads), val(assembly_id), path(assembly)

        output:
        tuple val(sample_id), path("${sample_id}.sorted.bam") 


    script:

    """ 
    bwa index ${assembly} 

    bwa mem -t 24 ${assembly} ${reads[0]} ${reads[1]} > ${sample_id}.aligned.sam
    samtools view -S -b ${sample_id}.aligned.sam | samtools sort -o ${sample_id}.sorted.bam -
    samtools index ${sample_id}.sorted.bam

    """

}


process merqury {

    publishDir "", mode:'copy'


    input:
    tuple val(assembly_id), path(assembly), val(sample_id), path(meryldb)

    output:
    path "${assembly.baseName}.merqury.log"
    path "${assembly.baseName}.merqury"


    script:

    """

    export MERQURY=/usr/local/share/merqury
    \$MERQURY/merqury.sh ${meryldb} ${assembly} '${assembly.baseName}.merqury' 2>&1 | tee '${assembly.baseName}.merqury.log'


    """

}


workflow {

    busco workflows 

   busco_acti_assemblies_ch = Channel.fromPath(params.assembly)

    //busco_db_ch =  Channel.fromPath(params.actinopterygii_odb10, type: 'dir', checkIfExists: true)   //if you have the db in a directory use this 

    //join_busco_ch = busco_acti_assemblies_ch.join(busco_db_ch)  //if you have the db in a directory use this 
    
   // busco_acti(join_busco_ch)  //if you have the db in a directory use this 
    
    busco_acti_ch = busco_acti(busco_acti_assemblies_ch)  //if you are calling the bucos_db as part of the container use this

    compile_busco_acti(busco_acti_ch[1])
    //    .view()

    //busco_vert_assemblies_ch = Channel
    //    .fromPath(params.assembly)
        //.view()
    
    //busco_vert_ch = busco_vert(busco_vert_assemblies_ch)

    //compile_busco_vert(busco_vert_ch[1])

    //bwa workflows 
    ref_ch = Channel.fromPath(params.assembly, checkIfExists: true)
            .map { it -> [it[5], it] }  //update the matching key per your file path and direcotry structure
                //.view ()

    fastq_ch = Channel.fromFilePairs(params.fastq, checkIfExists: true)
                    //.view()

   //  Join the channels based on the matching keys
    join_ch = fastq_ch.join(ref_ch, by: 2)
    //.view()


    bwa_align(join_ch)
   // .view()

 // merqury workflow 

   assembly_ch = Channel.fromPath(params.assembly, checkIfExists: true)
        .map { it -> [it[5], it] }
    .view()    
    
    meryldb_ch = Channel.fromPath(params.meryldb, type: 'dir', checkIfExists: true)
        .map { it -> [it[5], it] }      //update the matching key per your file path and direcotry structure
        .view()

  combine_ch = meryldb_ch.join(assembly_ch, by: 2)
    //.view()

    merqury(combine_ch)
   // .view()

}
