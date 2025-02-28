include {generate_standard_filename} from "${projectDir}/external/pipeline-Nextflow-module/modules/common/generate_standardized_filename/main.nf"

workflow extract_mtDNA {
    take:
    ich
    main:
    if (params.input_type == 'BAM') {
        extract_mtDNA_BAMQL(ich)
        extracted_mt_reads = extract_mtDNA_BAMQL.out.extracted_mt_reads
    }
    else { // input_type == CRAM
        extract_mtDNA_SAMtools(ich)
        extracted_mt_reads = extract_mtDNA_SAMtools.out.extracted_mt_reads
    }
    emit:
    extracted_mt_reads
}

process extract_mtDNA_BAMQL {
    container params.BAMQL_docker_image

    //  extracted mt DNA
    publishDir {"${params.output_dir_base}/intermediate/${task.process.replace(':', '/')}_${sample_name}/"},
        enabled: params.save_intermediate_files,
        pattern: "extracted_mt_reads_*",
        mode: 'copy',
        saveAs: {"${output_filename_base}.bam"}

    //logs
    ext log_dir_suffix: { "/${sample_name}" }

    input:
        tuple(
            val(type),
            val(sample_name),
            path(input_bam_file),
            path(bam_index_file)
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
        bamql -b -o "extracted_mt_reads_${type}_${sample_name}.bam" -f "${input_bam_file}" "(chr(M) & mate_chr(M)) | (chr(Y) & after(${params.chrY_extraction_region}) & mate_chr(M))"
        """
}

process extract_mtDNA_SAMtools {
    container params.SAMtools_docker_image

    //  extracted mt DNA
    publishDir {"${params.output_dir_base}/intermediate/${task.process.replace(':', '/')}_${sample_name}/"},
        enabled: params.save_intermediate_files,
        pattern: "extracted_mt_reads_*",
        mode: 'copy',
        saveAs: {"${output_filename_base}.bam"}

    //logs
    ext log_dir_suffix: { "/${sample_name}" },
        containerOptions: { cram_reference_genome -> "--volume ${cram_reference_genome}:${cram_reference_genome}"}(file(params.cram_reference_genome).getParent())

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
        samtools view --bam --with-header --use-index --fetch-pairs --expr 'mrname=="chrM"' --reference ${params.cram_reference_genome} --output "extracted_mt_reads_${type}_${sample_name}.bam" "${input_cram_file}" chrM chrY:${params.chrY_extraction_region}
        """
}
