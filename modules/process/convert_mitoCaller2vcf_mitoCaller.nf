process convert_mitoCaller2vcf_mitoCaller {
    container params.mitoCaller2vcf_docker_image
        label 'process_medium'

    publishDir {"${params.base_output_dir}/output/"},
    pattern: "*.vcf",
    mode: 'copy'

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
      path '*.txt'


    script:
    """
    echo '${mitocaller_out.baseName} ${mitocaller_out}' > ${mitocaller_out.baseName}.list
    python3.8 /mitoCaller2vcf/mitoCaller2vcf.py -s ./${mitocaller_out.baseName}.list -y ${sample_name}_homoplasmy.vcf -o ${sample_name}.vcf
    ls > contents.txt
    """
}



