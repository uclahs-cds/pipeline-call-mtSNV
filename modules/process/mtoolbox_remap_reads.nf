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

process MTOOLBOX_remap_reads {
  container "blcdsdockerregistry/call-mtsnv:mtoolbox-1.0.5" // TODO: rename the tag to 1.0.0
  containerOptions "--volume ${params.output_dir}:/src/imported/"
      
    memory amount_of_memory
    cpus number_of_cpus

  //containerptions "-v ${params.mtoolbox_out}:${params.rsrs_out} -v ${params.output_dir}:${params.extract_reads_out}"
  publishDir "${params.output_dir}", enabled: true, mode: 'copy'

  //  input:
  input:
    file bamql_out
    //from next_stage

  output: 
    file("OUT2-sorted_${bamql_out.baseName}.bam")      
      //into next_stage_2 
         

// !!!NOTE!!! Output file location can not be spceified or it breaks mtoolbox script when running a BAM file
  script:
  """
  mv ${bamql_out} '${bamql_out.baseName}.bam'

  printf "input_type='bam'\nref='RSRS'\ninput_path=${bamql_out}\n" > config_'${bamql_out.baseName}'.conf
  
  MToolBox.sh -i config_'${bamql_out.baseName}'.conf -m '-t 4'
  
  mv OUT_'${bamql_out.baseName}'/OUT2-sorted.bam OUT2-sorted_'${bamql_out.baseName}'.bam
  
  """
}

/*** Future Work 
- None
***/
