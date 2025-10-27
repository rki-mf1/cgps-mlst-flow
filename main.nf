#!/usr/bin/env nextflow
nextflow.enable.dsl=2

/******************************************************************************* 
* PROCESSES
*******************************************************************************/

// CGPS MLST process -----------------------------------------------------------
process CGPS_MLST {

    tag "Pathogenwatch (cg)MLST | Input: ${input_fasta.baseName}"
    publishDir "${params.publish_dir}/jsons", mode:'copy', overwrite: true
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'library://bajicv/pathogenwatch/mlst:v0.0.1' : 
        'library://bajicv/pathogenwatch/mlst:v0.0.1'}"

    input:
    path input_fasta
    path indexed_scheme_dir
    val scheme_name

    output:
    path("*.json"), emit: json

    script:
    """
    /usr/local/mlst/mlst.sh \\
        ${input_fasta} \\
        ${input_fasta.baseName}.json \\
        ${scheme_name} \\
        ${indexed_scheme_dir}
    """
}

// Process for summarizing json outputs ---------------------------------------
process SUMMARIZE_JSONS {

    tag "Create summary profile tables"
    publishDir "${params.publish_dir}", mode:'copy', overwrite: true
    conda "${baseDir}/envs/r_json_env.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'library://bajicv/r/tidyverse-jsonlite-optparse:latest' : 
        'library://bajicv/r/tidyverse-jsonlite-optparse:latest'}"
    
    input:
        file json_list_file
    
    output:
        path "profile_summary/*_info.tsv"
        path "profile_summary/*_profile_hashed.tsv"
        path "profile_summary/*_profile.tsv"
    
    script:
    """
    Rscript --vanilla ${baseDir}/bin/jsonList2tsvProfiles.R \
        -i ${json_list_file} \
        -o profile_summary
    """
}

/******************************************************************************* 
* MAIN WORKFLOW
*******************************************************************************/

workflow {
    // 1. Run CGPS-MLST on all input fasta files
    fastas_ch = Channel.fromPath("${params.input_dir}/*.{fna,fa,fasta}").flatten()
    
    jsons = CGPS_MLST(
        fastas_ch,
        params.indexed_scheme_dir, 
        params.scheme_name
        ).json.collect()

    // 2. Summarize all JSONs into one TSV
    json_list_ch = jsons.map { json -> json.join('\n') }
    SUMMARIZE_JSONS(json_list_ch)
}