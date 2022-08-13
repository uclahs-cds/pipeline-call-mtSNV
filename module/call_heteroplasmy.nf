include {generate_standard_filename} from "${projectDir}/external/pipeline-Nextflow-module/modules/common/generate_standardized_filename/main.nf"

process call_heteroplasmy {
    container params.heteroplasmy_script_docker_image
        label 'process_medium'

    // tsv
    publishDir {"${params.output_dir}/output/"},
        pattern: "*.tsv",
        mode: "copy",
        saveAs: { file(it).getName().startsWith("filtered") ?
            "${generate_standard_filename(
            "call-heteroplasmy-${params.call_heteroplasmy_version}",
            params.dataset_id,
            params.sample_id,
            [:]
            )}_filtered.tsv" :
            "${generate_standard_filename(
            "call-heteroplasmy-${params.call_heteroplasmy_version}",
            params.dataset_id,
            params.sample_id,
            [:]
            )}.tsv"
            }

    // info
    publishDir {"${params.output_dir}/intermediate/${task.process.split(':')[-1].replace('_', '-')}/"},
        enabled: params.save_intermediate_files,
        pattern: "*info",
        mode: "copy"

    //logs
    publishDir "${params.log_output_dir}/${task.process.split(':')[-1].replace('_', '-')}/",
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
    --output heteroplasmy_call.tsv \
    --ascat_stat
    """
}
