process call_mtSNV_mitoCaller {
    container params.mitocaller_docker_image
    containerOptions "-v ${params.directory_containing_mt_ref_genome_chrRSRS_files}:/mitochondria-ref/"
    // Note - reference genome needs to be mounted otherwise mitocaller fails
        label 'process_high'


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
      tuple(
        val(type),
        val(sample_name),
        path(mtoolbox_out)
        )

    output:
     tuple val(type), val(sample_name), path("${type}_${sample_name}_mitocaller.tsv.gz"), emit: main_output
     tuple val(type), val(sample_name), path("${type}_${sample_name}_mitocaller.tsv"), emit: tsv_output
      path '.command.*'

    script:
    """
    /MitoCaller/mitoCaller -m -b "${mtoolbox_out}"  -r /mitochondria-ref/chrRSRS.fa -v ${type}_${sample_name}_mitocaller.tsv
    gzip -k ${type}_${sample_name}_mitocaller.tsv
    """
}



