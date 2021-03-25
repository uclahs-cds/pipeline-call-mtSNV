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
    container "blcdsdockerregistry/mtoolbox:1.2.1._git_g_2018-07-04_a_2-4.2.0" // TODO: rename the tag to 1.0.0
    containerOptions "--volume ${params.gmapdb}:/src/gmapdb/ --volume ${params.genome_fasta}:/src/genome_fasta/ "
    publishDir "${params.output_dir}", 
    enabled: true, 
    mode: 'copy'

    //memory proclamation
    memory amount_of_memory
    cpus number_of_cpus

    //logs
    publishDir path: params.log_output_dir,
    pattern: ".command.*",
    mode: "copy",
    saveAs: { "logs_mtoolbox/${file(bamql_out).getSimpleName()}/log${file(it).getName()}" } 

    publishDir "${params.output_dir}", enabled: true, mode: 'copy'

    input:
      path bamql_out

    output: 
      path("OUT2-sorted_${bamql_out.baseName}.bam"), emit: bams
      path '.command.*'
      
         

// !!!NOTE!!! Output file location can not be spceified or it breaks mtoolbox script when running a BAM file
  script:
  """
  mv ${bamql_out} '${bamql_out.baseName}.bam'

  printf "input_type='bam'\nref='RSRS'\ninput_path=${bamql_out}\ngsnapdb=/src/gmapdb/\nfasta_path=/src/genome_fasta/\n" > config_'${bamql_out.baseName}'.conf
  
  MToolBox.sh -i config_'${bamql_out.baseName}'.conf -m '-t ${task.cpus}'
  
  mv OUT_'${bamql_out.baseName}'/OUT2-sorted.bam OUT2-sorted_'${bamql_out.baseName}'.bam
  
  """
}

/*** Future Work 
- Remove params.outputdir from mount and incorporate directly in script.
***/
