include {generate_standard_filename; sanitize_string} from "${projectDir}/external/pipeline-Nextflow-module/modules/common/generate_standardized_filename/main.nf"

process call_heteroplasmy {
    container params.heteroplasmy_script_docker_image
    label 'process_medium'

    // filtered tsv
    publishDir {"${params.output_dir}/output/"},
        pattern: "filtered_heteroplasmy_call.tsv",
        mode: "copy",
        saveAs: { "${output_filename_base}_filtered.tsv" }

    // unfiltered tsv
    publishDir {"${params.output_dir}/intermediate/${task.process.split(':')[-1].replace('_', '-')}/"},
        enabled: params.save_intermediate_files,
        pattern: "*[!{filtered}]*heteroplasmy_call.tsv",
        mode: "copy",
        saveAs: { "${output_filename_base}.tsv" }

    // info
    publishDir {"${params.output_dir}/intermediate/${task.process.split(':')[-1].replace('_', '-')}/"},
        enabled: params.save_intermediate_files,
        pattern: "*info",
        mode: "copy",
        saveAs: { "${output_filename_base}.pl.programinfo" }

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
        output_filename_base = generate_standard_filename(
            "call-heteroplasmy-${params.call_heteroplasmy_version}",
            params.dataset_id,
            "${tumour_sample_name}",
            [:]
            )
        """
        perl /src/script/call_heteroplasmy_mitocaller.pl \
        --normal ${normal_mitocaller_out} \
        --tumour ${tumour_mitocaller_out} \
        --output heteroplasmy_call.tsv \
        --ascat_stat
        """
}
