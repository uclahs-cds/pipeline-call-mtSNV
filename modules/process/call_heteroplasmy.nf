process call_heteroplasmy {
    container params.heteroplasmy_script_docker_image
        label 'process_medium'

    publishDir "${params.output_dir}",
        enabled: true,
        mode: 'copy',
        saveAs: {"${params.run_name}_${params.date}/call_heteroplasmy/${file(it).getName()}" }

    // tsv
    publishDir params.output_dir,
        pattern: "*.tsv",
        mode: "copy",
        saveAs: {"${params.run_name}_${params.date}/call_heteroplasmy/${file(it).getName()}" }

    // info
    publishDir params.output_dir,
        pattern: "*.info",
        mode: "copy",
        saveAs: {"${params.run_name}_${params.date}/call_heteroplasmy/${file(it).getName()}" }

    //logs
    publishDir params.output_dir,
        pattern: ".command.*",
        mode: "copy",
        saveAs: {"${params.run_name}_${params.date}/log/call_heteroplasmy/log${file(it).getName()}" }

    input:
        tuple(
        val(normal_key),
        val(normal_sample_name),
        path(normal_mitocaller_out)
        )

        tuple(
        val(tumour_key),
        val(tumour_sample_name),
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
