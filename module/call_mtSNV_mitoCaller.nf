include {generate_standard_filename} from "${projectDir}/external/pipeline-Nextflow-module/modules/common/generate_standardized_filename/main.nf"

process call_mtSNV_mitoCaller {
    container params.mitocaller_docker_image
    containerOptions "-v ${params.mt_ref_genome_dir}:/mitochondria-ref/"
    // Note - reference genome needs to be mounted otherwise mitocaller fails
        label 'process_high'

    publishDir {"${params.output_dir}/output/"},
        pattern: "${type}_${sample_name}_mitoCaller.tsv",
        mode: 'copy',
        saveAs: { "${output_filename_base}.tsv" }

    publishDir {"${params.output_dir}/intermediate/${task.process.split(':')[-1].replace('_', '-')}_${sample_name}/"},
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
     tuple val(type), val(sample_name), path("${type}_${sample_name}_mitoCaller.tsv.gz"), emit: mt_variants_gz
     tuple val(type), val(sample_name), path("${type}_${sample_name}_mitoCaller.tsv"), emit: mt_variants_tsv
      path '.command.*'

    script:
    output_filename_base = generate_standard_filename(
       "mitoCaller-${params.mitocaller_version}",
        params.dataset_id,
        "${sample_name}",
        [:])
    """
    /MitoCaller/mitoCaller -m -b "${mtoolbox_out}"  -r /mitochondria-ref/chrRSRS.fa -v ${type}_${sample_name}_mitoCaller.tsv
    gzip -k ${type}_${sample_name}_mitoCaller.tsv
    """
}



