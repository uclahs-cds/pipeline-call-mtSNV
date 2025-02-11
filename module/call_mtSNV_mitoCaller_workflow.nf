include { generate_standard_filename } from "${projectDir}/external/pipeline-Nextflow-module/modules/common/generate_standardized_filename/main.nf"
include { generate_checksum_PipeVal  } from '../external/pipeline-Nextflow-module/modules/PipeVal/generate-checksum/main.nf' addParams(
    options: [
        output_dir: "${params.output_dir_base}/output",
        docker_image_version: params.pipeval_version,
        main_process: "./",
        checksum_alg: 'sha512'
        ]
    )

workflow call_mtSNV {
    take:
    bam_for_mitoCaller

    main:
    call_mtSNV_mitoCaller( bam_for_mitoCaller )
    convert_mitoCaller2vcf_mitoCaller( call_mtSNV_mitoCaller.out.mt_variants_tsv )
    generate_checksum_PipeVal(convert_mitoCaller2vcf_mitoCaller.out.vcf.flatten())

    if (params.sample_mode == 'paired') {
        call_mtSNV_mitoCaller.out.mt_variants_gz.branch{
            normal: it[0] == 'normal'
            tumor: it[0] == 'tumor'
            }
            .set{ mitoCaller_forked_ch }
        call_heteroplasmy( mitoCaller_forked_ch.normal, mitoCaller_forked_ch.tumor )
        }

    emit:
    vcf = convert_mitoCaller2vcf_mitoCaller.out.vcf
}

process call_mtSNV_mitoCaller {
    container params.mitocaller_docker_image
    containerOptions "-v ${params.mt_ref_genome_dir}:/mitochondria-ref/"
    // Note - reference genome needs to be mounted otherwise mitocaller fails

    publishDir {"${params.output_dir_base}/intermediate/${task.process.split(':')[-1].replace('_', '-')}_${sample_name}/"},
        enabled: params.save_intermediate_files,
        pattern: "${type}_${sample_name}_mitoCaller.tsv",
        mode: 'copy',
        saveAs: { "${output_filename_base}.tsv" }

    //logs
    ext log_dir: { "${task.process.split(':')[-1].replace('_', '-')}_${sample_name}" }

    input:
        tuple(
            val(type),
            val(sample_name),
            path(mtoolbox_out)
            )

    output:
        tuple val(type), val(sample_name), path("${type}_${sample_name}_mitoCaller.tsv.gz"), emit: mt_variants_gz
        tuple val(type), val(sample_name), path("${type}_${sample_name}_mitoCaller.tsv"), emit: mt_variants_tsv
        path '.command.*'

    script:
        output_filename_base = generate_standard_filename(
            "mitoCaller-${params.mitocaller_version}",
            params.dataset_id,
            "${sample_name}",
            [:]
            )
        """
        /MitoCaller/mitoCaller -m -b "${mtoolbox_out}"  -r /mitochondria-ref/chrRSRS.fa -v ${type}_${sample_name}_mitoCaller.tsv
        gzip -k ${type}_${sample_name}_mitoCaller.tsv
        """
    }


process convert_mitoCaller2vcf_mitoCaller {
    container params.mitoCaller2vcf_docker_image

    publishDir {"${params.output_dir_base}/output/"},
        pattern: "*.vcf",
        mode: 'copy'

    //logs
    ext log_dir: { "${task.process.split(':')[-1].replace('_', '-')}_${sample_name}" }

    input:
        tuple(
            val( type ),
            val( sample_name ),
            path( mitocaller_out )
            )

    output:
        path '*.vcf', emit: vcf
        path '.command.*'

    script:
        output_filename_base = generate_standard_filename(
            "mitoCaller2vcf-${params.mitoCaller2vcf_version}",
            params.dataset_id,
            "${sample_name}",
            [:]
            )
        homoplasmy_vcf_header = "#CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO\tFORMAT\t${sample_name}"
        """
        echo '${mitocaller_out.baseName} ${mitocaller_out}' > ${mitocaller_out.baseName}.list
        python3.8 /mitoCaller2vcf/mitoCaller2vcf.py -s ./${mitocaller_out.baseName}.list -y ${sample_name}_homoplasmy.vcf -o {output_filename_base}.vcf
        last_header_line=\$(grep -n '^##' ${sample_name}_homoplasmy.vcf | tail -1 | cut -d: -f1)
        head -n \$last_header_line ${sample_name}_homoplasmy.vcf > tmpfile
        echo '${homoplasmy_vcf_header}' >> tmpfile
        tail -n +\$((\$last_header_line + 1)) ${sample_name}_homoplasmy.vcf >> tmpfile
        mv tmpfile ${output_filename_base}_homoplasmy.vcf
        """
}

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