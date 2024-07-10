include {generate_standard_filename; sanitize_string} from "${projectDir}/external/pipeline-Nextflow-module/modules/common/generate_standardized_filename/main.nf"

process call_heteroplasmy {
    container params.heteroplasmy_script_docker_image

    // filtered tsv
    publishDir {"${params.output_dir_base}/output/"},
        pattern: "filtered_heteroplasmy_call.tsv",
        mode: "copy",
        saveAs: { "${output_filename_base}_filtered.tsv" }

    // unfiltered tsv
    publishDir {"${params.output_dir_base}/intermediate/${task.process.split(':')[-1].replace('_', '-')}/"},
        enabled: params.save_intermediate_files,
        pattern: "*[!{filtered}]*heteroplasmy_call.tsv",
        mode: "copy",
        saveAs: { "${output_filename_base}.tsv" }

    // info
    publishDir {"${params.output_dir_base}/intermediate/${task.process.split(':')[-1].replace('_', '-')}/"},
        enabled: params.save_intermediate_files,
        pattern: "*info",
        mode: "copy",
        saveAs: { "${output_filename_base}.pl.programinfo" }

    //logs
    ext log_dir: { "${task.process.split(':')[-1].replace('_', '-')}" }

    input:
        tuple(
            val(normal_key),
            val(normal_sample_name),
            path(normal_mitocaller_out)
            )

        tuple(
            val(tumor_key),
            val(tumor_sample_name),
            path(tumor_mitocaller_out)
            )

    output:
        path '*.tsv'
        path '.command.*'
        path '*info'

    script:
        output_filename_base = generate_standard_filename(
            "call-heteroplasmy-${params.call_heteroplasmy_version}",
            params.dataset_id,
            "${tumor_sample_name}",
            [:]
            )
        """
        perl /src/script/call_heteroplasmy_mitocaller.pl \
        --normal ${normal_mitocaller_out} \
        --tumour ${tumor_mitocaller_out} \
        --output heteroplasmy_call.tsv \
        --ascat_stat
        """
}
