process extract_mtDNA_BAMQL {
    container params.BAMQL_docker_image
        label 'process_medium'

    //  extracted mt DNA
    publishDir {"${params.base_output_dir}/${sample_name}/${params.bamql_version}/output/"},
        pattern: "extracted_mt_reads_*",
        mode: 'copy'

    //logs
    publishDir "${params.log_output_dir}/process-log/${params.bamql_version}/${task.process.split(':')[-1].replace('_', '-')}/",
        pattern: ".command.*",
        mode: "copy",
        saveAs: { "log${file(it).getName()}" }

  input:
    tuple(
      val(type),
      val(sample_name),
      path(input_bam_file)
      )

  output:
    tuple val(type), val(sample_name), path('extracted_mt_reads_*'), emit: extracted_mt_reads
    file '.command.*'

  script:
  """
  set -euo pipefail
  bamql -b -o "extracted_mt_reads_${type}_${sample_name}.bam" -f "${input_bam_file}" "(chr(M) & mate_chr(M)) | (chr(Y) & after(57000000) & mate_chr(M))"

  """
}