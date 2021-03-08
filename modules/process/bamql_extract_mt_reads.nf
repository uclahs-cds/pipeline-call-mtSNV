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
    tuple( path(normal), path(tumour)) //from input_ch
    //
  output: 
    
    tuple(
     file("${normal.baseName}_mt"),
     file("${tumour.baseName}_mt")
     )//into next_stage 
     

  script:
  """
  bamql -b -o extracted_mt_reads_'${normal.baseName}' -f '${normal}' "(chr(M) & mate_chr(M)) | (chr(Y) & after(59000000) & mate_chr(M))"
  bamql -b -o extracted_mt_reads_'${tumour.baseName}' -f '${tumour}' "(chr(M) & mate_chr(M)) | (chr(Y) & after(59000000) & mate_chr(M))"

  """
}


/*** Future Work 
- Change resource allocation to refer to single module
- Single sample processing

***/