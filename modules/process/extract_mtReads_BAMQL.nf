//// Resource allocation ////
def number_of_cpus = (int) (Runtime.getRuntime().availableProcessors() / params.max_number_of_parallel_jobs)
if (number_of_cpus < 1) {
    number_of_cpus = 1
} 

def amount_of_memory = ((int) (((java.lang.management.ManagementFactory.getOperatingSystemMXBean()
    .getTotalPhysicalMemorySize() / (1024.0 * 1024.0 * 1024.0)) * 0.9) / params.max_number_of_parallel_jobs ))
if (amount_of_memory < 1) {
    amount_of_memory = 1
}
amount_of_memory = amount_of_memory.toString() + " GB"



//// Process ////

process extract_mtReads_BAMQL { 
    //container options
    container 'blcdsdockerregistry/bamql:1.5.1'
    containerOptions "--volume ${params.temp_dir}:/tmp"
    publishDir "${params.output_dir}", 
    enabled: true, 
    mode: 'copy',
    saveAs: {"${params.sample_name}/extract_mtReads_BAMQL/${file(it).getName()}" }
    
    //memory proclamation

    //logs
    publishDir path: params.output_dir,
    pattern: ".command.*",
    mode: "copy",
    saveAs: { "${params.sample_name}/logs_extract_mtReads_BAMQL/log${file(it).getName()}" } 

  input:
    tuple(path(input_file_x), val(type)) //from input_ch
   
  output: 
    path 'extracted_mt_reads_*', emit: bams //into next_stage 
    file '.command.*'
     
  script:
  """
  set -euo pipefail
  bamql -b -o 'extracted_mt_reads_${type}_${params.sample_name}' -f '${input_file_x}' "(chr(M) & mate_chr(M)) | (chr(Y) & after(57000000) & mate_chr(M))"
  """
}


/*** Future Work 
-Add conditional statement for bamql extraction depending on genome
***/
