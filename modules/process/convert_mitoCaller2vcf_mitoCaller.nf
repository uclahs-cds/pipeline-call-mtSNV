process convert_mitoCaller2vcf_mitoCaller {
    container params.mitoCaller2vcf_docker_image
        label 'process_medium'

    publishDir {"${params.base_output_dir}/${sample_name}/${params.mitoCaller2vcf_version}/output/"},
    enabled: true,
    mode: 'copy'

    //logs
    publishDir "${params.log_output_dir}/process-log/${params.mitoCaller2vcf_version}/${task.process.split(':')[-1].replace('_', '-')}/",
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
      path '*.txt'


    script:
    """
    echo '${mitocaller_out.baseName} ${mitocaller_out}' > ${mitocaller_out.baseName}.list
    python3.8 /mitoCaller2vcf/mitoCaller2vcf.py -s ./${mitocaller_out.baseName}.list -y ${sample_name}_homoplasmy.vcf -o ${sample_name}.vcf
    ls > contents.txt
    """
}



