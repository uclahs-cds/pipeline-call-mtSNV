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
    container "blcdsdockerregistry/mtoolbox:1.2.1._git_g_2018-07-04_a_2-4.2.0" // TODO: rename the tag to 1.2.1
    containerOptions "--volume ${params.gmapdb}:/src/gmapdb/ --volume ${params.genome_fasta}:/src/genome_fasta/ "
    

    // Main ouput recalibrated & reheadered reads
    publishDir params.output_dir, 
        pattern: "OUT2*",
        mode: 'copy',
        saveAs: {"${params.run_name}/mtoolbox_out/${file(it).getName()}" }
    
    // mtoolbox folder with supplementary files
    publishDir params.output_dir, 
        enabled: params.save_intermediate_files,
        pattern: "OUT_*",
        mode: 'copy',
        saveAs: {"${params.run_name}/mtoolbox_out/${file(it).getName()}" }
       
    //logs
    publishDir path: params.output_dir,
        pattern: ".command.*",
        mode: "copy",
        saveAs: {"${params.run_name}/logs_mtoolbox/log${file(it).getName()}" }
    

    //memory proclamation
    memory amount_of_memory
    cpus number_of_cpus

    input:
      path bamql_out

    output: 
      path("OUT2-sorted_${bamql_out.baseName}.bam"), emit: bams
      path '.command.*'
      path("OUT_${bamql_out.baseName}")
      
         

// !!!NOTE!!! Output file location can not be spceified or it breaks mtoolbox script when running a BAM file
  script:
  """
  mv ./${bamql_out} ./'${bamql_out.baseName}.bam'

  printf "input_type='bam'\nref='RSRS'\ninput_path=${bamql_out}\ngsnapdb=/src/gmapdb/\nfasta_path=/src/genome_fasta/\n" > config_'${bamql_out.baseName}'.conf
  
  MToolBox.sh -i config_'${bamql_out.baseName}'.conf -m '-t ${task.cpus}'
  
  mv ./OUT_'${bamql_out.baseName}'/OUT2-sorted.bam ./OUT2-sorted_'${bamql_out.baseName}'.bam
  
  """
}

/*** Future Work 
- Remove params.outputdir from mount and incorporate directly in script.
***/
