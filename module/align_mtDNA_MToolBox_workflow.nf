include {generate_standard_filename; sanitize_string} from "${projectDir}/external/pipeline-Nextflow-module/modules/common/generate_standardized_filename/main.nf"
include { generate_checksum_PipeVal                 } from '../external/pipeline-Nextflow-module/modules/PipeVal/generate-checksum/main.nf' addParams(
    options: [
        output_dir: "${params.output_dir_base}/output",
        docker_image_version: params.pipeval_version,
        main_process: "./",
        checksum_alg: 'sha512'
        ]
    )
include { run_index_SAMtools } from '../external/pipeline-Nextflow-module/modules/common/generate_index/main.nf' addParams(
    options: [
        output_dir: "${params.output_dir_base}/output",
        log_output_dir: params.log_output_dir,
        docker_image_version: params.samtools_version,
        main_process: "./"
    ]
)

workflow align_mtDNA {
    take:
    extracted_mt_reads

    main:
    align_mtDNA_MToolBox( extracted_mt_reads )

    align_mtDNA_MToolBox.out.aligned_mt_reads
        .map{ type, sample, bam -> bam } // [type, sample, path]
        .flatten()
        .set { bam_ch }

    bam_for_mitoCaller = align_mtDNA_MToolBox.out.aligned_mt_reads
    if (params.downsample_mtoolbox_bam) {
        downsample_BAM_Picard(align_mtDNA_MToolBox.out.aligned_mt_reads)
        bam_for_mitoCaller = downsample_BAM_Picard.out.downsampled_mt_reads

        bam_ch.mix(
            bam_for_mitoCaller
                .map{ type, sample, bam -> bam }
                .flatten()
            )
            .set{ bam_ch }
        }

    // generate_checksum_PipeVal(bam_channel)
    run_index_SAMtools(bam_ch)
    generate_checksum_PipeVal(bam_ch.mix(run_index_SAMtools.out.index))

    emit:
    bam_for_mitoCaller
}

process align_mtDNA_MToolBox {
    container params.MToolBox_docker_image

    // Main output recalibrated & reheadered reads
    publishDir {"${params.output_dir_base}/output/"},
        pattern: "${output_filename_base}.bam",
        mode: 'copy'

    publishDir {"${params.output_dir_base}/output/"},
        pattern: "{mt_classification_best_results.csv}",
        mode: 'copy',
        saveAs: {"${output_filename_base}_${sanitize_string(file(it).getName())}"}

    publishDir {"${params.output_dir_base}/output/"},
        pattern: "summary*.txt",
        mode: 'copy',
        saveAs: {"${output_filename_base}_summary.txt"}

    publishDir {"${params.output_dir_base}/intermediate/${task.process.split(':')[-1].replace('_', '-')}_${sample_name}/"},
        enabled: params.save_intermediate_files,
        pattern: "OUT_${bamql_out.baseName}/*",
        mode: 'copy',
        saveAs: {"OUT_${bamql_out.baseName}/${sanitize_string(file(it).getName())}"}

    publishDir {"${params.output_dir_base}/intermediate/${task.process.split(':')[-1].replace('_', '-')}_${sample_name}/"},
        enabled: params.save_intermediate_files,
        pattern: "{tmp,VCF_dict_tmp,test}",
        mode: 'copy',
        saveAs: {"${output_filename_base}_${sanitize_string(file(it).getName())}"}

    // mtoolbox folder with supplementary files
    publishDir {"${params.output_dir_base}/intermediate/${task.process.split(':')[-1].replace('_', '-')}_${sample_name}/"},
        enabled: params.save_intermediate_files,
        pattern: "*.{txt,conf,vcf,gz}",
        mode: 'copy',
        saveAs: {"${output_filename_base}_${sanitize_string(file(it).getName())}"}

    //logs
    ext log_dir: { "${task.process.split(':')[-1].replace('_', '-')}_${sample_name}" }
    ext containerOptions: { gmapdb, mt_ref_genome_dir -> "--volume \"${gmapdb}:/src/gmapdb/\" --volume \"${mt_ref_genome_dir}:/src/genome_fasta/\""}(params.gmapdb, params.mt_ref_genome_dir)


    input:
        tuple(
            val(type),
            val(sample_name),
            path(bamql_out)
            )

    output:
        tuple val(type), val(sample_name), path("${output_filename_base}.bam"), emit: aligned_mt_reads

        path '.command.*'
        path("OUT_${bamql_out.baseName}/*")
        path("*.csv")
        path("*.txt")
        path("*.gz")
        path("*.vcf")
        path("VCF_dict_tmp")
        path("tmp")
        path("*.conf")

// !!!NOTE!!! Output file location can not be specified withing the mtoolbox command or it breaks mtoolbox script when running a BAM file
// !!!NOTE!!! Location of the directory with the reference genome needs to be mounted on docker image. The actual file can not be called on. This is because MToolBox uses a script as an input that requires this file location.

    script:
        output_filename_base = generate_standard_filename(
            "MToolBox-${params.mtoolbox_version}",
            params.dataset_id,
            "${sample_name}",
            [:]
            )
        """
        printf "input_type='bam'\nref='RSRS'\ninput_path=${bamql_out}\ngsnapdb=/src/gmapdb/\nfasta_path=/src/genome_fasta/\n" > config_'${bamql_out.baseName}'.conf
        MToolBox.sh -i config_'${bamql_out.baseName}'.conf -m '-t ${task.cpus}'

        mv OUT_${bamql_out.baseName}/OUT2-sorted.bam ${output_filename_base}.bam
        """
}

process downsample_BAM_Picard {
    container params.picard_docker_image

    publishDir {"${params.output_dir_base}/output/"},
        pattern: "${output_filename_base}_downsampled.bam",
        mode: 'copy'

    publishDir {"${params.output_dir_base}/output/"},
        pattern: "*.bai",
        mode: 'copy',
        saveAs: { "${output_filename_base}_downsampled.bam.bai" }

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
        path("*.bai"), emit: bai_files, optional: true

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
            INPUT=$mtoolbox_out \
            OUTPUT=${output_filename_base}_downsampled.bam \
            METRICS_FILE=${output_filename_base}_downsampleSAM-metrics.txt \
            ACCURACY=${params.downsample_accuracy} \
            PROBABILITY=${params.probability_downsample} \
            RANDOM_SEED=${params.downsample_seed} \
            STRATEGY=${params.downsample_strategy} \
            CREATE_INDEX=${params.downsample_index} \
            VALIDATION_STRINGENCY=${params.downsample_validation_stringency} \
            TMP_DIR=${task.workDir}
        """
    }
