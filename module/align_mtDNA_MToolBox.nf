include {generate_standard_filename; sanitize_string} from "${projectDir}/external/pipeline-Nextflow-module/modules/common/generate_standardized_filename/main.nf"

process align_mtDNA_MToolBox {
    container params.MToolBox_docker_image
    containerOptions "--volume \"${params.gmapdb}:/src/gmapdb/\" --volume \"${params.mt_ref_genome_dir}:/src/genome_fasta/\""

    // Main output recalibrated & reheadered reads
    publishDir {"${params.output_dir_base}/output/"},
        pattern: "{OUT_${bamql_out.baseName}/OUT2-sorted.bam}",
        mode: 'copy',
        saveAs: {"${output_filename_base}.bam"}

    publishDir {"${params.output_dir_base}/output/"},
        pattern: "{mt_classification_best_results.csv,summary*.txt,prioritized_variants.txt}",
        mode: 'copy',
        saveAs: {"${output_filename_base}_${sanitize_string(file(it).getName())}"}

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

    input:
        tuple(
            val(type),
            val(sample_name),
            path(bamql_out)
            )

    output:
        tuple val(type), val(sample_name), path("OUT_${bamql_out.baseName}/OUT2-sorted.bam"), emit: aligned_mt_reads

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
        """
}
