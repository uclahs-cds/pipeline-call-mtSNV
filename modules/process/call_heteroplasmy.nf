process call_heteroplasmy {
    container params.heteroplasmy_script_docker_image
        label 'process_medium'

    // tsv
    publishDir {"${params.base_output_dir}/output/"},
        pattern: "*.tsv",
        mode: "copy"

    // info
    publishDir {"${params.base_output_dir}/intermediate/${task.process.split(':')[-1].replace('_', '-')}_${sample_name}/"},
        pattern: "*.info",
        mode: "copy"

    //logs
    publishDir "${params.log_output_dir}/${task.process.split(':')[-1].replace('_', '-')}_${sample_name}/",
        pattern: ".command.*",
        mode: "copy",
        saveAs: {"log${file(it).getName()}" }

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
    --output ${tumour_sample_name}_heteroplasmy_call.tsv \
    --ascat_stat
    """
}
