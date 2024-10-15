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

/*
 * pipeline input parameters
 */
params.projectDir = params.rundir
params.reads = "${params.pooled}/*.{R1,R2}.fq.gz"
params.multiqc = "${params.projectDir}/${params.RUN}/multiqc"
params.scriptPath = "${baseDir}/bin/fastp-json2tsv.R"

// Print the loaded config values (for debugging)
println "RUN: ${params.RUN}"
println "Project Directory: ${params.projectDir}"
println "Reads: ${params.reads}"
