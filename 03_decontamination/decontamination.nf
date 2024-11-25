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

// Assign config values to params, 
params.date = config['DATE']
params.wrkdir = config['WRKDIR']
params.RUN = config['RUN']
params.pooled = config['pooled']
params.results ="$params.wrkdir/${params.date}_results"
params.projectDir = config['rundir']


// Define the pattern to match sample directories
samplePattern = params.projectDir + "/OG*"
// Define the pattern to match assembly files
assemblyPattern = samplePattern + "/assemblies/genome/*.fasta.gz"
// Call the assemblies using the assembly pattern
params.assembly = file(assemblyPattern)

params.scriptPath="${baseDir}/bin/fcs.py"
params.singularity="/software/projects/pawsey0812/tpeirce/.nextflow_singularity/ftp.ncbi.nlm.nih.gov-genomes-TOOLS-FCS-releases-0.4.0-fcs-gx.sif"
//_________________________________________________________________________________________________________
// |||| Processes ||||
//_________________________________________________________________________________________________________

    //_________________________________________________________________________________________________________
    // fcs-gx_find - NCBI find contamination process
    //_________________________________________________________________________________________________________


    process fcsgx_find {
        tag "fcsgx_find on $og_num"

        publishDir "${params.projectDir}/${og_num}/assemblies/genome", mode:'copy'

        input:
            tuple val(og_num), val(sample_id), path(assembly)

        output: 
            tuple val(og_num), val(sample_id), path(assembly), path("NCBI/*.fcs_gx_report.txt")     , emit: fcs_gx_report
            tuple val(og_num), val(sample_id), path("NCBI/*.taxonomy.rpt")                          , emit: taxonomy_report
            path "NCBI/versions.yml"                                                                , emit: versions
    
        when:
            task.ext.when == null || task.ext.when   

        script:
        
            def args = task.ext.args ?: ''
            def prefix = task.ext.prefix ?: "${sample_id}"
                    
            """
            echo ‘copying’
                mkdir /tmp/gxdb/
                cp -v ${params.GXDB_LOC}/gxdb/all.gxi /tmp/gxdb/
                cp -v ${params.GXDB_LOC}/gxdb/all.gxs /tmp/gxdb/
                cp -v ${params.GXDB_LOC}/gxdb/all.meta.jsonl /tmp/gxdb/
                cp -v ${params.GXDB_LOC}/gxdb/all.blast_div.tsv.gz /tmp/gxdb/ 
                cp -v ${params.GXDB_LOC}/gxdb/all.taxa.tsv /tmp/gxdb/ 
            echo ‘done copying’ 
            ls -l /tmp/gxdb/
           
            taxid=\$(cat "${params.results}/taxon.txt" | grep -w ${og_num} | awk -F'\\t' '{print \$4}')
            echo "taxid: \$taxid"
            python3 /app/bin/run_gx \\
                --fasta ${assembly} \\
                --tax-id \$taxid \\
                --out-dir ./NCBI \\
                --gx-db /tmp/gxdb \\
                --debug               
                
        
            cat <<-END_VERSIONS > NCBI/versions.yml
            "${task.process}":
                python: \$(python3 --version 2>&1 | sed -e "s/Python //g")
                FCS-GX: \$( gx --help | sed '/build/!d; s/.*:v//; s/-.*//' )
            END_VERSIONS
            """                    
    }


    //_________________________________________________________________________________________________________
    // fcs-gx_clean - clean genome
    //_________________________________________________________________________________________________________

    process fcsgx_clean { 
        debug true
        tag "fcsgx_clean on $og_num"

        publishDir "${params.projectDir}/${og_num}/assemblies/genome", mode:'copy'
          
        input:
       
            tuple val(og_num), val(sample_id), path(assembly), path(action_report) //fcs-gx_find.out.fcs_gx_report
        
        output:
            tuple val(og_num), path("NCBI/${sample_id}.v129mh.rc.fasta"), emit: cleaned
            path("NCBI/${og_num}.contam.fasta")                         , emit: contam

        script:

            // Exit if running this module with -profile conda / -profile mamba
            if (workflow.profile.tokenize(',').intersect(['conda', 'mamba']).size() >= 1) {
                error "FCS_FCSGX module does not support Conda. Please use Docker / Singularity / Podman instead."
            }
            def args = task.ext.args ?: ''
            def prefix = task.ext.prefix ?: "${sample_id}"
            def FCSGX_VERSION = '0.5.4'
        
            """
            export taxid=\$(cat "${params.results}/taxon.txt" | grep -w ${og_num} | awk -F'\\t' '{print \$4}')
            mkdir -p NCBI
            gunzip ${assembly}
            gx clean-genome \\
                --input "${sample_id}.v129mh.fasta" \\
                --action-report "${action_report}" \\
                --output "NCBI/${sample_id}.v129mh.rc.fasta" \\
                --contam-fasta-out "NCBI/${og_num}.contam.fasta"
                $args
        
            cat <<-END_VERSIONS > versions.yml
            "${task.process}":
                FCS-GX: $FCSGX_VERSION
            END_VERSIONS
            """
        
            stub:
            // Exit if running this module with -profile conda / -profile mamba
            if (workflow.profile.tokenize(',').intersect(['conda', 'mamba']).size() >= 1) {
                error "FCS_FCSGX module does not support Conda. Please use Docker / Singularity / Podman instead."
            }
            def prefix = task.ext.prefix ?: "${sample_id}"
            def FCSGX_VERSION = '0.5.4'
        
            """
            mkdir -p NCBI
            touch NCBI/${sample_id}.v129mh.rc.fasta
            touch NCBI/${og_num}.contam.fasta
        
            cat <<-END_VERSIONS > versions.yml
            "${task.process}":
                FCS-GX: \$( gx --help | sed '/build/!d; s/.*:v//; s/-.*//' )
            END_VERSIONS
            """
    }


    //_________________________________________________________________________________________________________
    // bbmap_filter - filter NCBI
    //_________________________________________________________________________________________________________

    process bbmap_filter { 
        tag "bbmap_filter on $og_num"

        publishDir "${params.projectDir}/${og_num}/assemblies/genome", mode:'copy'

        input:
            tuple val(og_num), val(sample_id), path(assembly), path(action_report), path(cleaned) //path(assembly) isnt used its just a tag along

        output:
            path ("NCBI/${sample_id}.filter_report.txt")                        , emit: filter_report
            tuple path("NCBI/${sample_id}.review_scaffolds_1kb.txt"), path("NCBI/${sample_id}.contig_count_500bp.txt"), path("NCBI/${sample_id}.v129mh.rf.fa")
            tuple val(og_num), val(sample_id), file("${sample_id}.v129mh.fa")   , emit: filtered_fasta
            
        script:
            """ 
            export tax=\$(cat "${params.results}/taxon.txt" | grep -w ${og_num} | awk -F'\t' '{print \$4}')
            
            # count the number of contigs and the number of base pairs being removed across EXCLUDE and TRIM 
            mkdir -p NCBI

            count=\$(grep -w EXCLUDE "${action_report}" | cut -f 1 | sort -u | wc -l)
            bp=\$(grep -w EXCLUDE "${action_report}" | awk '{sum+=\$3-\$2+1}END{print sum}')
            echo "EXCLUDE \$count \$bp" >> "NCBI/${sample_id}.filter_report.txt"


            count=\$(grep -w TRIM "${action_report}" | cut -f 1 | sort -u | wc -l)
            bp=\$(grep -w TRIM "${action_report}" | awk '{sum+=\$3-\$2+1}END{print sum}')
            echo "TRIM \$count \$bp" >> "NCBI/${sample_id}.filter_report.txt"


            # count the number of contigs 1000bp or less and number of total bp to be filtered
            count=\$(grep -w REVIEW "${action_report}" | awk '\$4 <= 1000'| cut -f 1 | sort -u | wc -l)
            bp=\$(grep -w REVIEW "${action_report}" | awk '\$4 <= 1000'| awk '{sum+=\$3-\$2+1}END{print sum}')
            echo "REVIEW \$count \$bp" >> "NCBI/${sample_id}.filter_report.txt"


            #generate a txt file with the name of the contigs that are in review that are less that 1000bp.
            grep -w REVIEW "${action_report}" | awk '\$4 <= 1000' | awk '{print \$1}' > "NCBI/${sample_id}.review_scaffolds_1kb.txt"


            # remove these contigs 
            filterbyname.sh \\
                in="${cleaned}" \\
                out="NCBI/${sample_id}.v129mh.rf.fa" \\
                names="NCBI/${sample_id}.review_scaffolds_1kb.txt" exclude 


            # Wait for the first bbmap script to complete before moving on
            wait


            grep -v '^>' "NCBI/${sample_id}.v129mh.rf.fa" | awk 'length(\$0) < 500 {count++} END {print "Number of contigs less than 500bp:", count}' > "NCBI/${sample_id}.contig_count_500bp.txt"


            #remove the contigs that are less than 500bp from the assembly 
            reformat.sh \\
                in="NCBI/${sample_id}.v129mh.rf.fa" \\
                out="${sample_id}.v129mh.fa" \\
                minlength=500
          
            """
    }


    //_________________________________________________________________________________________________________
    // Find adaptor contamination process
    //_________________________________________________________________________________________________________

    process find_adaptors {
        tag "find_adaptors on $og_num"

        publishDir "${params.projectDir}/${og_num}/assemblies/genome/NCBI", mode:'copy'

        input:
            tuple val(og_num), val(sample_id), path(filtered_fasta)
        
        output:
            path(adaptor)
            tuple val(og_num), path("adaptor/cleaned_sequences/*")      , emit: cleaned_assembly, optional: false
            tuple val(og_num), path("adaptor/*.fcs_adaptor_report.txt") , emit: adaptor_report
            tuple val(og_num), path("adaptor/*.fcs_adaptor.log")        , emit: log
            tuple val(og_num), path("adaptor/*.pipeline_args.yaml")     , emit: pipeline_args
            tuple val(og_num), path("adaptor/*.skipped_trims.jsonl")    , emit: skipped_trims

        script:
            def args = task.ext.args ?: '--euk' // --prok || --euk
            def prefix = task.ext.prefix ?: "${sample_id}"
            def FCSADAPTOR_VERSION = '0.5.0' // WARN: Version information not provided by tool on CLI. Please update this string when bumping container versions.

            """            
            av_screen_x \\
                -o adaptor/ \\
                $args \\
                ${filtered_fasta} 
            
            # Add in the prefix to the files
            
                mv "adaptor/fcs_adaptor_report.txt"    "adaptor/${prefix}.fcs_adaptor_report.txt"
                mv "adaptor/fcs_adaptor.log"           "adaptor/${prefix}.fcs_adaptor.log"
                mv "adaptor/pipeline_args.yaml"        "adaptor/${prefix}.pipeline_args.yaml"
                mv "adaptor/skipped_trims.jsonl"       "adaptor/${prefix}.skipped_trims.jsonl"
            
            cat <<-END_VERSIONS > versions.yml
            "${task.process}":
                FCS-adaptor: $FCSADAPTOR_VERSION
            END_VERSIONS

            """
    }


    //_________________________________________________________________________________________________________
    // Filter adaptors process
    //_________________________________________________________________________________________________________

    process filter_adaptors {
        //debug true
        tag "filter_adaptors on $og_num"

        publishDir "${params.projectDir}/${og_num}/assemblies/genome", mode:'copy'
          
        input:       
            tuple val(og_num), val(sample_id), path(filtered_fasta), path(adaptor_report)    

        output:
            tuple val(og_num), val(sample_id), path("${sample_id}.rmadapt.fasta")   , emit: cleaned
            path("${sample_id}.adaptor-contam.fasta")                               , emit: contam

        script:
            def args = task.ext.args ?: ''
            def prefix = task.ext.prefix ?: "${sample_id}"
            def FCSGX_VERSION = '0.5.4'
        
            """  
            python3 --version
            #sed -i '1i ##[["FCS genome report",2,' "$adaptor_report"        
            gx clean-genome \\
                --input ${filtered_fasta} \\
                --action-report "${adaptor_report}" \\
                --output "${sample_id}.rmadapt.fasta" \\
                --contam-fasta-out "${sample_id}.adaptor-contam.fasta"
                
        
            cat <<-END_VERSIONS > versions.yml
            "${task.process}":
                FCS-GX: $FCSGX_VERSION
            END_VERSIONS
            """      
    }


    //_________________________________________________________________________________________________________
    // Tiara find contamination process
    //_________________________________________________________________________________________________________

    process tiara_find_contam {
        tag "tiara_find_contam on $og_num"

        publishDir "${params.projectDir}/${og_num}/assemblies/genome/tiara", mode:'copy'

        input:
            tuple val(og_num), val(sample_id), path(fasta)

        output:
            tuple val(og_num), path("${sample_id}.tiara.contig_removal.txt"), emit: filter
            tuple val(og_num), path("${sample_id}.tiara.txt"), path("${sample_id}.tiara_filter_summary.txt"), emit: classifications
            tuple val(og_num), path("log_*.{txt,txt.gz}")   , emit: log
            tuple val(og_num), path("*.{fasta,fasta.gz}")   , emit: fasta, optional: true
            path "versions.yml"                             , emit: versions


        script:
            def args = '-m 1000 --tf mit pla pro -t 4 -p 0.65 0.60 --probabilities'
            def VERSION = '1.0.3' // WARN: Version information not provided by tool on CLI. Please update this string when bumping container versions.
            
            """
            tiara -i ${fasta} \\
                -o ${sample_id}.tiara.txt \\
                --threads 4 \\
                ${args}
         
            #Compile the results of tiara, this script will generate a summary txt file which will show across each category the number of contigs and number of bp to be filtered. 
            tiara_report="${sample_id}.tiara.txt"
            output_file="${sample_id}.tiara_filter_summary.txt"
            contig_list="${sample_id}.tiara.contig_removal.txt"

            echo -e "Category\\tnum_contigs\\tbp" > "\$output_file"
            count=\$(grep -w mitochondrion \$tiara_report | wc -l)      
            bp=\$(grep -w mitochondrion "\$tiara_report" | awk -F'len=' '{sum += \$2} END {print sum}')
            echo "Mitochondrion \$count \$bp" >> \$output_file
            count1=\$(grep -w plastid \$tiara_report | wc -l)
            bp1=\$(grep -w plastid "\$tiara_report" | awk -F'len=' '{sum += \$2} END {print sum}')
            echo "Plastid \$count1 \$bp1" >> \$output_file 
            count2=\$(grep -w prokarya \$tiara_report | wc -l)
            bp2=\$(grep -w prokarya "\$tiara_report" | awk -F'len=' '{sum += \$2} END {print sum}')
            echo "Prokarya \$count2 \$bp2" >> \$output_file
            
            #Next, print a list of the contigs to filter out based off tiara.txt file output, this will be passed to bbmap to filter the contigs 
            
            grep -w mitochondrion "\$tiara_report" | awk '{print \$1}' >> "\$contig_list"
            grep -w plastid "\$tiara_report" | awk '{print \$1}' >> "\$contig_list"
            grep -w prokarya "\$tiara_report" | awk '{print \$1}' >> "\$contig_list"

            cat <<-END_VERSIONS > versions.yml
            "${task.process}":
                tiara: ${VERSION}
            END_VERSIONS

            """
    }


    //_________________________________________________________________________________________________________
    // Filter tiara resulults using bbmap
    //_________________________________________________________________________________________________________

    process filter_tiara {
        tag "filter_tiara on $og_num"

        publishDir "${params.projectDir}/${og_num}/assemblies/genome", mode:'copy'

        input:
            tuple val(og_num), val(sample_id), path(fasta), path(contig_list)

        output:
            path("${sample_id}.v129mh.fna")

        script:
                
            """
            filterbyname.sh \\
                in="${fasta}" \\
                out="${sample_id}.v129mh.fna" \\
                names="${contig_list}" \\
                exclude
            """
    }


//_________________________________________________________________________________________________________
// |||| Workflow ||||
//_________________________________________________________________________________________________________

workflow {
    fasta_ch = Channel
        .fromPath(params.assembly, checkIfExists: true)
        .map { file ->
            def fileName = file.getFileName().toString()  // Get the file name with extension
            def og_num = fileName.tokenize(".").get(0)  // Extract OG number
            def sample_id = fileName.tokenize(".").take(3).join(".")  // Get the first three parts $OG.$TECH.$RUNDATE
            return tuple(og_num, sample_id, file.toString())  // Return the tuple
        }
        .view()

    fcsgx_find(fasta_ch)

    fcsgx_clean(fcsgx_find.out.fcs_gx_report)

    fcsgx_combined_ch = fcsgx_find.out.fcs_gx_report
        .join(fcsgx_clean.out.cleaned, by: 0) //Join with the other output using the first value (ognum)
    
    bbmap_filter(fcsgx_combined_ch)

    find_adaptors(bbmap_filter.out.filtered_fasta)

    filter_adaptors_combined_ch = bbmap_filter.out.filtered_fasta
        .join(find_adaptors.out.adaptor_report, by: 0)
    
    filter_adaptors(filter_adaptors_combined_ch)

    tiara_find_contam(filter_adaptors.out.cleaned)

    filter_tiara_ch = filter_adaptors.out.cleaned
        .join(tiara_find_contam.out.filter, by: 0) //Join with the other output using the first value (ognum)    

    filter_tiara(filter_tiara_ch)
}
