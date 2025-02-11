include {generate_standard_filename} from "${projectDir}/external/pipeline-Nextflow-module/modules/common/generate_standardized_filename/main.nf"

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
        output_file = "${output_filename_base}.vcf"
        output_file_homoplasmy = "${output_filename_base}_homoplasmy.vcf"
        """
        echo '${mitocaller_out.baseName} ${mitocaller_out}' > ${mitocaller_out.baseName}.list
        python3.8 /mitoCaller2vcf/mitoCaller2vcf.py -s ./${mitocaller_out.baseName}.list -y ${output_file_homoplasmy} -o ${output_file}
        last_header_line=\$(grep -n '^##' ${output_file_homoplasmy} | tail -1 | cut -d: -f1)
        head -n \$last_header_line ${output_file_homoplasmy} > tmpfile
        echo '${homoplasmy_vcf_header}' >> tmpfile
        tail -n +\$((\$last_header_line + 1)) ${output_file_homoplasmy} >> tmpfile
        mv tmpfile ${output_file_homoplasmy}
        """
}



