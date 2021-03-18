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

process BAMQL_extract_mt_reads { 
    container 'blcdsdockerregistry/call-mtsnv:bamql-1.5.1'
    containerOptions "--volume ${params.temp_dir}:/tmp"
    publishDir "${params.output_dir}", enabled: true, mode: 'copy'
 
    memory amount_of_memory
    cpus number_of_cpus

  input:
    tuple(path(input_file_x), val(type)) //from input_ch
    //
  output: 
    
    file 'extracted_mt_reads_*' //into next_stage 
     

  script:
  """
  bamql -b -o extracted_mt_reads_'${type}'_'${input_file_x.baseName}' -f '${input_file_x}' "(chr(M) & mate_chr(M)) | (chr(Y) & after(59000000) & mate_chr(M))"

  """
}


/*** Future Work 
-None
***/