process extract_mtDNA_BAMQL { 
    //container options
    container 'blcdsdockerregistry/bamql:1.6.1'
    containerOptions "--volume ${params.temp_dir}:/tmp"
    publishDir "${params.output_dir}", 
    enabled: true, 
    mode: 'copy',
    saveAs: {"${params.run_name}_${params.date}/extract_mtReads_BAMQL/${sample_name}/${file(it).getName()}" }

    //logs
    publishDir path: params.output_dir,
    pattern: ".command.*",
    mode: "copy",
    saveAs: { "${params.run_name}_${params.date}/log/extract_mtReads_BAMQL/log${file(it).getName()}" } 

  input:
    tuple(
      val(type),
      val(sample_name),
      path(input_bam_file) 
      ) //from input_ch
   
  output: 
    path 'extracted_mt_reads_*', emit: bams 
    val sample_name, emit: sample_name
    val type, emit: type
    file '.command.*'
     
  script:
  """
  set -euo pipefail
  bamql -b -o 'extracted_mt_reads_${type}_${sample_name}' -f '${input_bam_file}' "(chr(M) & mate_chr(M)) | (chr(Y) & after(57000000) & mate_chr(M))"

  """
}