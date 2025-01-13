include {generate_standard_filename} from "${projectDir}/external/pipeline-Nextflow-module/modules/common/generate_standardized_filename/main.nf"

process downsample_SAM_Picard {
    container params.picard_docker_image

    publishDir {"${params.output_dir_base}/intermediate/${task.process.split(':')[-1].replace('_', '-')}_${sample_name}/"},
        enabled: params.save_intermediate_files,
        pattern: "*.bam",
        mode: 'copy',
        saveAs: { "${output_filename_base}_downsampled.bam" }

    publishDir {"${params.output_dir_base}/intermediate/${task.process.split(':')[-1].replace('_', '-')}_${sample_name}/"},
            enabled: params.save_intermediate_files,
            pattern: "*.bai",
            mode: 'copy',
            saveAs: { "${output_filename_base}_downsampled.bam.bai" }

    publishDir {"${params.output_dir_base}/intermediate/${task.process.split(':')[-1].replace('_', '-')}_${sample_name}/"},
        enabled: params.save_intermediate_files,
        pattern: "*.md5",
        mode: 'copy',
        saveAs: { "${output_filename_base}_downsampled.bam.md5" }

    publishDir {"${params.output_dir_base}/QC/${task.process.split(':')[-1].replace('_', '-')}_${sample_name}/"},
        enabled: params.save_intermediate_files,
        pattern: "*metrics.txt",
        mode: 'copy',
        saveAs: { "${output_filename_base}_downsampleSAM-metrics.txt" }

    //logs
    ext log_dir: { "${task.process.split(':')[-1].replace('_', '-')}_${sample_name}" }

    input:
        tuple(
            val(type),
            val(sample_name),
            path(mtoolbox_out)
            )

    output:
        tuple val(type), val(sample_name), path("*.bam"), emit: downsampled_mt_reads
        path '.command.*'
        path("*downsampleSAM-metrics.txt")
        path("*.bai"), optional: true
        path("*.md5"), optional: true

    script:
        output_filename_base = generate_standard_filename(
            "MToolBox-${params.mtoolbox_version}",
            params.dataset_id,
            "${sample_name}",
            [:]
            )
        """
        java -jar /usr/local/share/picard-slim-${params.picard_version}-0/picard.jar \
        DownsampleSam \
            I=$mtoolbox_out \
            O=${output_filename_base}_downsampled.bam \
            M=${output_filename_base}_downsampleSAM-metrics.txt \
            A=${params.downsample_accuracy} \
            P=${params.probability_downsample} \
            R=${params.downsample_seed} \
            S=${params.downsample_strategy} \
            CREATE_INDEX=${params.downsample_index} \
            CREATE_MD5_FILE=${params.downsample_md5} \
            TMP_DIR="/scratch"
        """
    }

