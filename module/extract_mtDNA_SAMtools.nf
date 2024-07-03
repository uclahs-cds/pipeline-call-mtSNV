include {generate_standard_filename} from "${projectDir}/external/pipeline-Nextflow-module/modules/common/generate_standardized_filename/main.nf"

process extract_mtDNA_SAMtools {
    container params.SAMtools_docker_image

    //  extracted mt DNA
    publishDir {"${params.output_dir_base}/intermediate/${task.process.split(':')[-1].replace('_', '-')}_${sample_name}/"},
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
            path(input_cram_file),
            path(cram_index_file)
            )

    output:
        tuple val(type), val(sample_name), path('extracted_mt_reads_*'), emit: extracted_mt_reads
        file '.command.*'

    script:
        output_filename_base = generate_standard_filename(
            "SAMtools-${params.samtools_version}",
            params.dataset_id,
            "${sample_name}",
            [:]
            )
        """
        set -euo pipefail
        samtools view --bam --with-header --use-index --fetch-pairs --expr 'mrname=="chrM"' --output "extracted_mt_reads_${type}_${sample_name}.bam" "${input_cram_file}" chrM chrY:57000000
        """
}
