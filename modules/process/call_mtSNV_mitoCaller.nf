process call_mtSNV_mitoCaller {
    container params.mitocaller_docker_image
    containerOptions "-v ${params.directory_containing_mt_ref_genome_chrRSRS_files}:/mitochondria-ref/"
    // Note - reference genome needs to be mounted otherwise mitocaller fails
        label 'process_high'


    publishDir {"${params.base_output_dir}/output/"},
        pattern: "${type}_${sample_name}_mitocaller.tsv",
        mode: 'copy'

    publishDir {"${params.base_output_dir}/intermediate/${task.process.split(':')[-1].replace('_', '-')}_${sample_name}/"},
        enabled: params.save_intermediate_files,
        pattern: "*.gz",
        mode: "copy"

    //logs
    publishDir "${params.log_output_dir}/${task.process.split(':')[-1].replace('_', '-')}_${sample_name}/",
    pattern: ".command.*",
    mode: "copy",
    saveAs: { "log${file(it).getName()}" }

    input:
      tuple(
        val(type),
        val(sample_name),
        path(mtoolbox_out)
        )

    output:
     tuple val(type), val(sample_name), path("${type}_${sample_name}_mitocaller.tsv.gz"), emit: mt_variants_gz
     tuple val(type), val(sample_name), path("${type}_${sample_name}_mitocaller.tsv"), emit: mt_variants_tsv
      path '.command.*'

    script:
    """
    /MitoCaller/mitoCaller -m -b "${mtoolbox_out}"  -r /mitochondria-ref/chrRSRS.fa -v ${type}_${sample_name}_mitocaller.tsv
    gzip -k ${type}_${sample_name}_mitocaller.tsv
    """
}



