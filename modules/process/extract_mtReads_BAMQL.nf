//// Process ////

process extract_mtReads_BAMQL { 
    //container options
    container 'blcdsdockerregistry/bamql:1.5.1'
    containerOptions "--volume ${params.temp_dir}:/tmp"
    publishDir "${params.output_dir}", 
    enabled: true, 
    mode: 'copy',
    saveAs: {"${params.sample_name}_${params.date}/extract_mtReads_BAMQL/${file(it).getName()}" }

    //memory proclamation
    memory amount_of_memory
    cpus number_of_cpus

    //logs
    publishDir path: params.output_dir,
    pattern: ".command.*",
    mode: "copy",
    saveAs: { "${params.sample_name}_${params.date}/logs_extract_mtReads_BAMQL/log${file(it).getName()}" } 

  input:
    tuple(path(input_file_x), val(type)) //from input_ch
   
  output: 
    path 'extracted_mt_reads_*', emit: bams //into next_stage 
    file '.command.*'
    val type, emit: type
     
  script:
  """
  set -euo pipefail
  bamql -b -o 'extracted_mt_reads_${type}_${params.sample_name}' -f '${input_file_x}' "(chr(M) & mate_chr(M)) | (chr(Y) & after(57000000) & mate_chr(M))"
  touch type
  echo ${type} > type
  """
}


/*** Future Work 
-Add conditional statement for bamql extraction depending on genome
***/
