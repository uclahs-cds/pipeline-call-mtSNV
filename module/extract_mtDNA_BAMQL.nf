include {generate_standard_filename} from "${projectDir}/external/pipeline-Nextflow-module/modules/common/generate_standardized_filename/main.nf"

process extract_mtDNA_BAMQL {
    container params.BAMQL_docker_image
    label 'process_medium'

    //  extracted mt DNA
    publishDir {"${params.output_dir}/intermediate/${task.process.split(':')[-1].replace('_', '-')}_${sample_name}/"},
        enabled: params.save_intermediate_files,
        pattern: "extracted_mt_reads_*",
        mode: 'copy',
        saveAs: {"${output_filename_base}.bam"}

    //logs
    publishDir "${params.log_output_dir}/${task.process.split(':')[-1].replace('_', '-')}_${sample_name}/",
        pattern: ".command.*",
        mode: "copy",
        saveAs: { "log${file(it).getName()}" }

    input:
        tuple(
            val(type),
            val(sample_name),
            path(input_bam_file)
            )

    output:
        tuple val(type), val(sample_name), path('extracted_mt_reads_*'), emit: extracted_mt_reads
        file '.command.*'

    script:
        output_filename_base = generate_standard_filename(
            "BAMQL-${params.bamql_version}",
            params.dataset_id,
            "${sample_name}",
            [:]
            )
        """
        set -euo pipefail
        bamql -b -o "extracted_mt_reads_${type}_${sample_name}.bam" -f "${input_bam_file}" "(chr(M) & mate_chr(M)) | (chr(Y) & after(57000000) & mate_chr(M))"
        """
}
