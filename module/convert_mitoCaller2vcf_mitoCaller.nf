include {generate_standard_filename} from "${projectDir}/external/pipeline-Nextflow-module/modules/common/generate_standardized_filename/main.nf"

process convert_mitoCaller2vcf_mitoCaller {
    container params.mitoCaller2vcf_docker_image
    label 'process_medium'

    publishDir {"${params.output_dir_base}/output/"},
        pattern: "*output.vcf",
        mode: 'copy',
        saveAs: { "${output_filename_base}.vcf" }

    publishDir {"${params.output_dir_base}/output/"},
        pattern: "*homoplasmy.vcf",
        mode: 'copy',
        saveAs: { "${output_filename_base}_homoplasmy.vcf" }

    //logs
    publishDir "${params.log_output_dir}/${task.process.split(':')[-1].replace('_', '-')}_${sample_name}/",
        pattern: ".command.*",
        mode: "copy",
        saveAs: {"log${file(it).getName()}" }

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
        homoplasmy_vcf_header = "#CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO\tFORMAT\t${type}_${sample_name}_mitoCaller"
        """
        echo '${mitocaller_out.baseName} ${mitocaller_out}' > ${mitocaller_out.baseName}.list
        python3.8 /mitoCaller2vcf/mitoCaller2vcf.py -s ./${mitocaller_out.baseName}.list -y ${sample_name}_homoplasmy.vcf -o ${sample_name}_output.vcf
        last_header_line=\$(grep -n '^##' ${sample_name}_homoplasmy.vcf | tail -1 | cut -d: -f1)
        head -n \$last_header_line ${sample_name}_homoplasmy.vcf > tmpfile
        echo '${homoplasmy_vcf_header}' >> tmpfile
        tail -n +\$((\$last_header_line + 1)) ${sample_name}_homoplasmy.vcf >> tmpfile
        mv tmpfile ${sample_name}_homoplasmy.vcf
        """
}



