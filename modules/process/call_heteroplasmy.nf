//// Process ////

process call_heteroplasmy {
    container "${params.heteroplasmy_script_docker_image}"
    publishDir "${params.output_dir}", 
    enabled: true, 
    mode: 'copy',
    saveAs: {"${params.run_name}_${params.date}/call_heteroplasmy/${file(it).getName()}" }

    // tsv
    publishDir params.output_dir, 
    pattern: "*.tsv",
    mode: "copy",
    saveAs: {"${params.run_name}_${params.date}/call_heteroplasmy/${file(it).getName()}" }

        // tsv
    publishDir params.output_dir, 
    pattern: "*.info",
    mode: "copy",
    saveAs: {"${params.run_name}_${params.date}/call_heteroplasmy/${file(it).getName()}" }


    //logs
    publishDir params.output_dir, 
    pattern: ".command.*",
    mode: "copy",
    saveAs: {"${params.run_name}_${params.date}/log/call_heteroplasmy/${file(it).getName()}" }

    input:
        tuple( 
        path(normal_mitocaller_out),
        path(tumour_mitocaller_out)
        ) 
    
    output:
        path '*.tsv'
        path '.command.*'
        path '*info'

    script:
    """
     perl /src/script/call_heteroplasmy_mitocaller.pl \
    --normal ${normal_mitocaller_out} \
    --tumour ${tumour_mitocaller_out} \
    --ascat_stat
    mv test.tsv ${normal_mitocaller_out.baseName}_vs_${tumour_mitocaller_out.baseName}.tsv
    """
}
