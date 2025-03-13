#!/usr/bin/env nextflow
nextflow.enable.dsl = 2

//_________________________________________________________________________________________________________
/* The folowing block of code reads in the config file where all the variables and directiories are defined
    for the run. These are then passed into parameters for the nextflow pipeline. */
//_________________________________________________________________________________________________________

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


//_________________________________________________________________________________________________________
// |||| Pipeline input parameters ||||
//_________________________________________________________________________________________________________

/* Defining all of the parameters for the nextflow.
    Params that have '= config[]' are pulling values from the config file.
    The word in the [''] is the variable as defined in the config file before the = 
    To pull more params use the variable name from the configfile.txt in square brackets.
*/

params.date = config['DATE']
params.projectDir = config['rundir'] //this is the OUTPUT dir
params.wrkdir = config['WRKDIR']
params.results =config['results']

// Define the pattern to match sample directories
samplePattern = params.projectDir + "/OG*"
// Define the pattern to match assembly files
assemblyPattern = samplePattern + "/assemblies/genome/*.fna"
// Call the assemblies using the assembly pattern
params.assembly = file(assemblyPattern)

params.sample_ID = file("$projectDir").getName()
params.fastq = samplePattern + "/fastp/*.{R1,R2}.fastq.gz"
params.meryldb =  samplePattern + "/kmers/*.meryl"
params.scriptPath = "${baseDir}/bin/busco2tsv.R"
params.lineage_acti_db = "/scratch/references/busco_db/actinopterygii_odb10"
params.lineage_vert_db = "/scratch/references/busco_db/vertebrata_odb10"


//_________________________________________________________________________________________________________
// |||| Processes ||||
//_________________________________________________________________________________________________________

    //_________________________________________________________________________________________________________
    // Pull lineage process
    //_________________________________________________________________________________________________________

    process lineage {
        tag "$ognum lineage"
        input:
        tuple val(ognum), path(reads), path(assembly)

        output:
        tuple val(ognum), path(reads), path(assembly), env(lineage)
        

        script:
        """
        DATE=${params.date}
        lineage=\$(grep -w "${ognum}" ${params.results}/taxon.txt | awk -F '\\t' '{print \$2}')
        echo "\$lineage" > lineage.txt
        
        """

    }




    //_________________________________________________________________________________________________________
    // Busco acti process
    //_________________________________________________________________________________________________________

    process busco_acti {
        tag "$ognum busco_acti"
        //debug true
        publishDir "$params.projectDir/${assembly.simpleName}/assemblies/genome/busco_acti", mode: 'copy'

        input:
        tuple val(ognum), path(reads), path(assembly), val(lineage)

        when: 
        "${lineage}" == 'actinopterygii'

        output:
        path "${assembly}.busco.acti.short_summary.txt", emit: summary_txt
        path "${assembly}.busco.acti.short_summary.json", emit: summary_json
        tuple val(ognum), path("${assembly}.busco.acti.full_table.tsv"), emit: busco_tsv
        path "${assembly}.busco.acti.busco_sequences.tar.gz", emit: sequence_tar_gz
        path "${assembly}.busco.acti.busco_sequences.tar.gz.md5", emit: md5
        path "${assembly}.busco.acti.missing_busco_list.tsv", emit: missing_tsv
        path "${assembly}.busco.acti.logs", emit: logs
        path "versions_busco.yml"

        script:
        """
        busco \\
            -i ${assembly} \\
            -o ${assembly}.busco.acti \\
            -l ${params.lineage_acti_db} \\
            -m genome \\
            -c 8 \\
            -f
        
        mv ${assembly}.busco.acti/run_actinopterygii_odb10/short_summary.txt ${assembly}.busco.acti.short_summary.txt
        mv ${assembly}.busco.acti/run_actinopterygii_odb10/short_summary.json ${assembly}.busco.acti.short_summary.json
        mv ${assembly}.busco.acti/run_actinopterygii_odb10/full_table.tsv ${assembly}.busco.acti.full_table.tsv
        mv ${assembly}.busco.acti/run_actinopterygii_odb10/busco_sequences ${assembly}.busco.acti.busco_sequences
        mv ${assembly}.busco.acti/run_actinopterygii_odb10/missing_busco_list.tsv ${assembly}.busco.acti.missing_busco_list.tsv
        mv ${assembly}.busco.acti/logs ${assembly}.busco.acti.logs

        tar -czvf ${assembly}.busco.acti.busco_sequences.tar.gz ${assembly}.busco.acti.busco_sequences
        md5sum ${assembly}.busco.acti.busco_sequences.tar.gz > ${assembly}.busco.acti.busco_sequences.tar.gz.md5 &&  rm -rf ${assembly}.busco.acti.busco_sequences
        
        cat <<-END_VERSIONS > versions_busco.yml
        "${task.process}":
            busco: \$( busco --version 2>&1 | sed 's/^BUSCO //' )
        END_VERSIONS
        """
    }

    process compile_busco_acti {
        tag "$ognum compile_busco_acti"
        publishDir "$params.projectDir/${assembly.simpleName}/assemblies/genome/busco_acti", mode: 'copy'

        input: 
        file assembly

        output:
        file ("${assembly}.tsv")

        script:
        """
        Rscript ${params.scriptPath} "${assembly}"
        """
    }

    //_________________________________________________________________________________________________________
    // Busco Vert process
    //_________________________________________________________________________________________________________

    process busco_vert {
        tag "$ognum busco_vert"
        //debug true
        publishDir "$params.projectDir/${assembly.simpleName}/assemblies/genome/busco_vert", mode: 'copy'

        input: 
        tuple val(ognum), path(reads), path(assembly), val(lineage)

        when: 
        "${lineage}" == 'vertebrate'

        output:
        path "${assembly}.busco.vert.short_summary.txt", emit: summary_txt
        path "${assembly}.busco.vert.short_summary.json", emit: summary_json
        tuple val(ognum), path("${assembly}.busco.vert.full_table.tsv"), emit: busco_tsv
        path "${assembly}.busco.vert.busco_sequences.tar.gz", emit: sequence_tar_gz
        path "${assembly}.busco.vert.busco_sequences.tar.gz.md5", emit: md5
        path "${assembly}.busco.vert.missing_busco_list.tsv", emit: missing_tsv
        path "${assembly}.busco.vert.logs", emit: logs
        path "versions_busco.yml"

        script:
        """
        busco \\
        -i ${assembly} \\
        -o ${assembly}.busco.vert \\
        -l ${params.lineage_vert_db} \\
        -m genome \\
        -c 36 \\
        -f
        mv ${assembly}.busco.vert/run_vertebrata_odb10/short_summary.txt ${assembly}.busco.vert.short_summary.txt
        mv ${assembly}.busco.vert/run_vertebrata_odb10/short_summary.json ${assembly}.busco.vert.short_summary.json
        mv ${assembly}.busco.vert/run_vertebrata_odb10/full_table.tsv ${assembly}.busco.vert.full_table.tsv
        mv ${assembly}.busco.vert/run_vertebrata_odb10/busco_sequences ${assembly}.busco.vert.busco_sequences
        mv ${assembly}.busco.vert/run_vertebrata_odb10/missing_busco_list.tsv ${assembly}.busco.vert.missing_busco_list.tsv
        mv ${assembly}.busco.vert/logs ${assembly}.busco.vert.logs

        tar -czvf ${assembly}.busco.vert.busco_sequences.tar.gz ${assembly}.busco.vert.busco_sequences
        md5sum ${assembly}.busco.vert.busco_sequences.tar.gz > ${assembly}.busco.vert.busco_sequences.tar.gz.md5 &&  rm -rf ${assembly}.busco.vert.busco_sequences

        cat <<-END_VERSIONS > versions_busco.yml
        "${task.process}":
            busco: \$( busco --version 2>&1 | sed 's/^BUSCO //' )
        END_VERSIONS
        """
    }

    process compile_busco_vert {
        tag "$ognum compile_busco_vert"
        publishDir "$params.projectDir/${assembly.simpleName}/assemblies/genome/busco_vert", mode: 'copy'

        input: 
        file assembly

        output:
        file ("${assembly}.tsv")

        script:
        """
        Rscript ${params.scriptPath} "${assembly}"
        """
    }


    //_________________________________________________________________________________________________________
    // BWA index process
    //_________________________________________________________________________________________________________

        process BWAMEM2_INDEX {
            tag "$ognum BWAMEM2_INDEX"

            input:
                tuple val(ognum), path(reads), path(assembly), val(lineage)

            output:
                tuple val(ognum), path("bwamem2"), path(reads), path(assembly), val(lineage), emit: index
                path "versions_bwaindex.yml"             , emit: versions

            when:
                task.ext.when == null || task.ext.when

            script:
                def prefix = task.ext.prefix ?: "${assembly}"
                def args = task.ext.args ?: ''
                """
                mkdir -p bwamem2
                bwa-mem2 \\
                    index \\
                    $args \\
                    $assembly \\
                    -p bwamem2/${prefix}

                cat <<-END_VERSIONS > versions_bwaindex.yml
                "${task.process}":
                    bwamem2: \$(echo \$(bwa-mem2 version 2>&1) | sed 's/.* //')
                END_VERSIONS
                """

        }

    //_________________________________________________________________________________________________________
    // BWA align process - Acti
    //_________________________________________________________________________________________________________

        process BWAMEM2_MEM_ACTI {
            tag "$ognum BWAMEM2_MEM"
            publishDir "$params.projectDir/${assembly.simpleName}/assemblies/genome/bwa", mode: 'copy'

            input:
                tuple val(ognum), path(index), path(reads), path(assembly), val(lineage)

            output:
                tuple val(ognum), path("${ognum}.sorted.bam"), emit: sorted_bam
                path ("${ognum}-sn_results.tsv")
                path  "versions_bwa.yml"            , emit: versions

            when:
                "${lineage}" == 'actinopterygii'

            script:
                def args = task.ext.args ?: ''
                def args2 = task.ext.args2 ?: ''
                def prefix = task.ext.prefix ?: "${ognum}"
                
                def extension_pattern = /(--output-fmt|-O)+\s+(\S+)/
                def extension_matcher =  (args2 =~ extension_pattern)
                def extension = extension_matcher.getCount() > 0 ? extension_matcher[0][2].toLowerCase() : "bam"
                def reference = assembly && extension=="cram"  ? "--reference ${assembly}" : ""
                if (!assembly && extension=="cram") error "Fasta reference is required for CRAM output"

                """
                INDEX=`find -L ./ -name "*.amb" | sed 's/\\.amb\$//'`

                bwa-mem2 \\
                    mem \\
                    -t 24 \\
                    \$INDEX \\
                    $reads \\
                    | samtools view -b | samtools sort -o ${ognum}.sorted.bam -
                    samtools index ${ognum}.sorted.bam
                    wait
                    samtools stats ${ognum}.sorted.bam | grep "^SN" | cut -f 2- > ${ognum}-sn_results.tsv

                cat <<-END_VERSIONS > versions_bwa.yml
                "${task.process}":
                    bwamem2: \$(echo \$(bwa-mem2 version 2>&1) | sed 's/.* //')
                    samtools: \$(echo \$(samtools --version 2>&1) | sed 's/^.*samtools //; s/Using.*\$//')
                END_VERSIONS
                """

        }
    
    //_________________________________________________________________________________________________________
    // BWA align process - Vert
    //_________________________________________________________________________________________________________
        
        process BWAMEM2_MEM_VERT {
            tag "$ognum BWAMEM2_MEM"
            publishDir "$params.projectDir/${assembly.simpleName}/assemblies/genome/bwa", mode: 'copy'

            input:
                tuple val(ognum), path(index), path(reads), path(assembly), val(lineage)

            output:
                tuple val(ognum), path("${ognum}.sorted.bam"), emit: sorted_bam
                path ("${ognum}-sn_results.tsv")
                path  "versions_bwa.yml"            , emit: versions

            when:
                "${lineage}" == 'vertebrate'

            script:
                def args = task.ext.args ?: ''
                def args2 = task.ext.args2 ?: ''
                def prefix = task.ext.prefix ?: "${ognum}"
                
                def extension_pattern = /(--output-fmt|-O)+\s+(\S+)/
                def extension_matcher =  (args2 =~ extension_pattern)
                def extension = extension_matcher.getCount() > 0 ? extension_matcher[0][2].toLowerCase() : "bam"
                def reference = assembly && extension=="cram"  ? "--reference ${assembly}" : ""
                if (!assembly && extension=="cram") error "Fasta reference is required for CRAM output"

                """
                INDEX=`find -L ./ -name "*.amb" | sed 's/\\.amb\$//'`

                bwa-mem2 \\
                    mem \\
                    -t 48 \\
                    \$INDEX \\
                    $reads \\
                    | samtools view -b | samtools sort -o ${ognum}.sorted.bam -
                    samtools index ${ognum}.sorted.bam
                    wait
                    samtools stats ${ognum}.sorted.bam | grep "^SN" | cut -f 2- > ${ognum}-sn_results.tsv

                cat <<-END_VERSIONS > versions_bwa.yml
                "${task.process}":
                    bwamem2: \$(echo \$(bwa-mem2 version 2>&1) | sed 's/.* //')
                    samtools: \$(echo \$(samtools --version 2>&1) | sed 's/^.*samtools //; s/Using.*\$//')
                END_VERSIONS
                """

        }


    //_________________________________________________________________________________________________________
    // Merqury process
    //_________________________________________________________________________________________________________

    process merqury {
        tag "$ognum merqury"
        publishDir "$params.projectDir/${assembly.simpleName}/kmers", mode: 'copy'

        input:
            tuple val(ognum), path(meryldb), path(assembly)

        output:
            path("*.completeness.stats")
            path("*.png")
            path("*.qv")
            path "versions_merqury.yml"

        script:
            def VERSION = 1.3 // WARN: Version information not provided by tool on CLI. Please update this string when bumping container versions.
            """
            # Nextflow changes the container --entrypoint to /bin/bash (container default entrypoint: /usr/local/env-execute)
            # Check for container variable initialisation script and source it.
            if [ -f "/usr/local/env-activate.sh" ]; then
                set +u  # Otherwise, errors out because of various unbound variables
                . "/usr/local/env-activate.sh"
                set -u
            fi
            # limit meryl to use the assigned number of cores.
            export OMP_NUM_THREADS=1536

            merqury.sh \\
                ${meryldb} \\
                ${assembly} \\
                ${assembly.baseName}.merqury

            cat <<-END_VERSIONS > versions_merqury.yml
            "${task.process}":
                merqury: $VERSION
            END_VERSIONS
            """
    }

    //_________________________________________________________________________________________________________
    // Depthsizer process
    //_________________________________________________________________________________________________________

    process depthsizer {
        tag "$ognum depthsizer"
        publishDir "$params.projectDir/${assembly.simpleName}/assemblies/genome/depthsizer", mode: 'copy'

        input:
        tuple val(ognum), path(assembly), path(reads), file(sorted_bam), file(busco_full_table)
        
        
        output:
        path '*.fastmp.scdepth'
        path '*.gensize.tdt'
        path '*.depthsizer.fulltable.tsv'
        path '*.depthsizer.busco.dupcnv.tsv'

        script:
        """
        python /opt/depthsizer_code/scripts/depthsizer.py \\
            -seqin ${assembly} \\
            -bam '${sorted_bam}' \\
            -busco '${busco_full_table}' \\
            -reads ${reads[0]},${reads[1]} \\
            -basefile=${assembly}.depthsizer \\
            -forks 40 \\
            i=-1 v=0 > /dev/null 2>&1 || (exit 0)
        if [ -e *.fastmp.scdepth ] && [ -e *.gensize.tdt ] && [ -e *.depthsizer.fulltable.tsv ] && [ -e *.depthsizer.busco.dupcnv.tsv ]; then
            rm -rf tmpdir
            exit 0  
        else
            exit 1  
        fi
        """
    }

//_________________________________________________________________________________________________________
// |||| Workflow ||||
//_________________________________________________________________________________________________________

workflow {
    // Create a channel to read in the params.assembly .fna file, extract the OG number and the path
    assemblies_ch = Channel.fromPath(params.assembly, checkIfExists: true)
        .map { 
            def ognum = it.getFileName().toString().tokenize(".").get(0)
            return tuple(ognum, it)
        }
        
        //.view { tuple -> println "assemblies_ch Tuple: ${tuple}" }
    
    // Create a channel to pair the fastq files
    fastq_ch = Channel.fromFilePairs(params.fastq, checkIfExists: true)
        .map { pair ->
            def ognum = pair[0].tokenize('.').get(0) // Extract the part of the filename before the first full stop
           [ognum, pair[1]] // Create a new pair with the modified key (ognum) and the original value
        }
        
    // Join the channels based on the matching keys
    join_ch = fastq_ch.join(assemblies_ch, by: 0)
        
        // Check channel outputs
        //join_ch.subscribe { item -> println "bwa join: $item"}// this matches the OG num in the 0 positions of the tupples and then outputs: ognum, path:[fastq R1,R2], path:assembly
     
    
    //__________________________________________________________________________________
    // Lineage workflow
    //__________________________________________________________________________________
    
    // Run lineage process and create a channel
        lineage_ch = lineage(join_ch) // Run the process
            
    //__________________________________________________________________________________
    // BUSCO workflow
    //__________________________________________________________________________________
    
        // activates the busco processes, these process have a when statement and will only run when the lineage_ch is equal to the right database to be run.
        busco_acti(lineage_ch)
        compile_busco_acti(busco_acti.out.summary_json)

        busco_vert(lineage_ch)
        compile_busco_vert(busco_vert.out.summary_json)

        
    //__________________________________________________________________________________
    // BWA workflow
    //__________________________________________________________________________________

        // Run process
        BWAMEM2_INDEX(lineage_ch)
        BWAMEM2_MEM_ACTI(BWAMEM2_INDEX.out.index)
        BWAMEM2_MEM_VERT(BWAMEM2_INDEX.out.index)

    //__________________________________________________________________________________
    // Merqury workflow
    //__________________________________________________________________________________

        meryldb_ch = Channel.fromPath(params.meryldb, type: 'dir', checkIfExists: true)
            .map { 
                def ognum = it.getFileName().toString().tokenize(".").get(0)
                return tuple(ognum, it)
            }

        combine_ch = meryldb_ch.join(assemblies_ch, by: 0) // this matches the OG num in the 0 positions of the tupples and then outputs: ognum, path:meryldb, path:assembly
        // Check channel outputs
        combine_ch.subscribe { item -> println "merqury combine: $item"}
        
        merqury(combine_ch)


    //__________________________________________________________________________________
    // Depthsizer workflow
    //__________________________________________________________________________________
      
        //Depthsizer workflow  use the emit busco_table, sorted BAM file, assembly and reads files for input
        
        // Merge the outputs of busco_acti and busco_vert into a single channel
        merged_busco_output_ch = busco_acti.out.busco_tsv.mix(busco_vert.out.busco_tsv)
        
        // Merge the outputs of bwa alighn vert and acti into a single channel
        merged_bwa_aligm_output_ch = BWAMEM2_MEM_ACTI.out.sorted_bam.mix(BWAMEM2_MEM_VERT.out.sorted_bam)

        // Check channel outputs
        merged_busco_output_ch.subscribe { item -> println "busco merged: $item"}

        // Join channels so that all the data is for the same sample
        combined_ch = assemblies_ch
            .join(fastq_ch, by: 0)                  // Join assemblies_ch with fastq_ch using the first value (ognum)
            .join(merged_bwa_aligm_output_ch, by: 0)  // Join the resulting channel with bwa_align.out.sorted_bam using the first value (ognum)
            .join(merged_busco_output_ch, by: 0)    // Join with the other two channels using the first value (ognum)
        //combined_ch.subscribe { item -> println "Depthsizer combined: $item"} // Uncomment this if you want to check the output of the channel
        
        // Run process
        depthsizer(combined_ch)
    
}
