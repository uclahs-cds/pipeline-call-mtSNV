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
    tuple(
        path(extracted_normal_reads),
        path(extracted_tumor_reads),
    )//from next_stage

  output: 
      
        tuple(        
        file("OUT2-sorted_${extracted_normal_reads.baseName}.bam"), 
        file("OUT2-sorted_${extracted_tumor_reads.baseName}.bam")
         ) //into next_stage_2 
         

// !!!NOTE!!! Output file location can not be spceified or it breaks mtoolbox script when running a BAM file
  script:
  """
  mv ${extracted_normal_reads} '${extracted_normal_reads.baseName}.bam'
  mv ${extracted_tumor_reads} '${extracted_tumor_reads.baseName}.bam'

  printf "input_type='bam'\nref='RSRS'\ninput_path=${extracted_normal_reads}\n" > config4.conf
  printf "input_type='bam'\nref='RSRS'\ninput_path=${extracted_tumor_reads}\n" > config5.conf
  
  MToolBox.sh -i config4.conf -m '-t 4'
  MToolBox.sh -i config5.conf -m '-t 4'
  
  mv OUT_'${extracted_normal_reads.baseName}'/OUT2-sorted.bam OUT2-sorted_'${extracted_normal_reads.baseName}'.bam
  mv OUT_'${extracted_tumor_reads.baseName}'/OUT2-sorted.bam OUT2-sorted_'${extracted_tumor_reads.baseName}'.bam
  
  """
}

/*** Future Work 
- Change resource allocation to refer to single module
- Single sample processing
***/
