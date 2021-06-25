process call_mtSNV_mitoCaller {
    container "${params.mitocaller_docker_image}"
    containerOptions "-v ${params.directory_containing_mt_ref_genome_chrRSRS_files}:/mitochondria-ref/"
    // Note - reference genome needs to be mounted otherwise mitocaller fails
    
    
    publishDir "${params.output_dir}", 
        pattern: "${type}_${sample_name}_mitocaller.tsv", 
        mode: 'copy',
        saveAs: {"${params.run_name}_${params.date}/call_mtSNV_mitoCaller/${sample_name}/${file(it).getName()}" }
    
 
    publishDir path: params.output_dir,
        enabled: params.save_intermediate_files,
        pattern: "*.gz",
        mode: "copy",
        saveAs: {"${params.run_name}_${params.date}/call_mtSNV_mitoCaller/${sample_name}/${file(it).getName()}" }

    //logs
    publishDir path: params.output_dir,
    pattern: ".command.*",
    mode: "copy",
    saveAs: {"${params.run_name}_${params.date}/log/call_mtSNV_mitoCaller/log${file(it).getName()}" }

    input:
      file mtoolbox_out
      val sample_name 
      val type

    output: 
        
      path "${type}_${sample_name}_mitocaller.tsv", emit: tsv
      path "${type}_${sample_name}_mitocaller.tsv.gz", emit: gz
      val sample_name, emit: sample_name
      val type, emit: type
      path '.command.*' 
   
    script:
     //this statement is essential to track identity of file i.e. tumor, normal
    """
    
    /MitoCaller/mitoCaller -m -b "${mtoolbox_out}"  -r /mitochondria-ref/chrRSRS.fa -v ${type}_${sample_name}_mitocaller.tsv
    gzip -k ${type}_${sample_name}_mitocaller.tsv

    """
}



