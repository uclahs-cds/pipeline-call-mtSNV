process convert_mitoCaller2vcf_mitoCaller {
    container "${params.mitoCaller2vcf_docker_image}"
    label 'process_medium'

    
    publishDir "${params.output_dir}", 
    enabled: true, 
    mode: 'copy',
    saveAs: {"${params.run_name}_${params.date}/convert_mitoCaller2vcf_mitoCaller/${sample_name}/${file(it).getName()}" }

    //logs
    publishDir path: params.output_dir,
    pattern: ".command.*",
    mode: "copy",
    saveAs: {"${params.run_name}_${params.date}/log/convert_mitoCaller2vcf_mitoCaller/log${file(it).getName()}" }
    
    input:
      file mitocaller_out 
      val sample_name 
      val type

    output: 
        
      path '*.vcf', emit: vcf
      path '.command.*' 
   
   
    script:
    """
    echo '${mitocaller_out.baseName} ${mitocaller_out}' > ${mitocaller_out.baseName}.list
    python3.8 /mitoCaller2vcf/mitoCaller2vcf.py -s ./${mitocaller_out.baseName}.list -y ${sample_name}_homoplasmy.vcf -o ${sample_name}.vcf
    """
}



