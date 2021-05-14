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

process align_mtReads_MToolBox {
    container "blcdsdockerregistry/mtoolbox:1.2.1-b52269e" // TODO: rename the tag to 1.2.1
    containerOptions "--volume ${params.gmapdb}:/src/gmapdb/ --volume ${params.genome_fasta}:/src/genome_fasta/ "
    

    // Main ouput recalibrated & reheadered reads
    publishDir params.output_dir, 
        pattern: "OUT_${bamql_out.baseName}/${params.sample_name}_mtoolbox_OUT2-sorted.bam",
        mode: 'copy',
        saveAs: {"${params.sample_name}_${params.date}/align_mtReads_MToolBox/${file(it).getName()}" }
    
    // mtoolbox folder with supplementary files
    publishDir params.output_dir, 
        enabled: params.save_intermediate_files,
        pattern: "*.txt",
        mode: 'copy',
        saveAs: {"${params.sample_name}_${params.date}/align_mtReads_MToolBox/${file(it).getName()}" }
    
    // 
    publishDir params.output_dir, 
        enabled: params.save_intermediate_files,
        pattern: "*.csv",
        mode: 'copy',
        saveAs: {"${params.sample_name}_${params.date}/align_mtReads_MToolBox/${file(it).getName()}" }

    publishDir params.output_dir, 
        enabled: params.save_intermediate_files,
        pattern: "*.vcf",
        mode: 'copy',
        saveAs: {"${params.sample_name}_${params.date}/align_mtReads_MToolBox/${file(it).getName()}" }
 
    publishDir params.output_dir, 
        enabled: params.save_intermediate_files,
        pattern: "*.gz",
        mode: 'copy',
        saveAs: {"${params.sample_name}_${params.date}/align_mtReads_MToolBox/${file(it).getName()}" }

    publishDir params.output_dir, 
        enabled: params.save_intermediate_files,
        pattern: "VCF_dict_tmp",
        mode: 'copy',
        saveAs: {"${params.sample_name}_${params.date}/align_mtReads_MToolBox/${file(it).getName()}" }

    publishDir params.output_dir, 
        enabled: params.save_intermediate_files,
        pattern: "test",
        mode: 'copy',
        saveAs: {"${params.sample_name}_${params.date}/align_mtReads_MToolBox/${file(it).getName()}" }
              
    //logs
    publishDir path: params.output_dir,
        pattern: ".command.*",
        mode: "copy",
        saveAs: {"${params.sample_name}_${params.date}/logs_align_mtReads_MToolBox/log${file(it).getName()}" }
    

    //memory proclamation
    memory amount_of_memory
    cpus number_of_cpus

    input:
      path bamql_out
      val type

    output: 
      path("OUT_${bamql_out.baseName}/${params.sample_name}_mtoolbox_OUT2-sorted.bam"), emit: bams
      val type, emit: type
      //file 'test'
      //val $type, emit: type
      path '.command.*'
      path("OUT_${bamql_out.baseName}")
      path("contents.txt")
      path("*.csv")
      path("*.txt")
      path("*.gz")
      path("*.vcf")
      path("VCF_dict_tmp")
      
         

// !!!NOTE!!! Output file location can not be spceified withing the mtoolbox command or it breaks mtoolbox script when running a BAM file

  script:
  type = type //this statement is essential to track identity of file i.e. tumor, normal
  """

  mv ./${bamql_out} ./'${bamql_out.baseName}.bam'

  printf "input_type='bam'\nref='RSRS'\ninput_path=${bamql_out}\ngsnapdb=/src/gmapdb/\nfasta_path=/src/genome_fasta/\n" > config_'${bamql_out.baseName}'.conf
  
  MToolBox.sh -i config_'${bamql_out.baseName}'.conf -m '-t ${task.cpus}'

  mv OUT_${bamql_out.baseName}/OUT2-sorted.bam OUT_${bamql_out.baseName}/${params.sample_name}_mtoolbox_OUT2-sorted.bam
  
  


  ls > contents.txt

  """
}

/*** Future Work 
touch type
  echo ${type} > $type
  mv ./OUT_'${bamql_out.baseName}'/OUT2-sorted.bam ./OUT2-sorted_'${bamql_out.baseName}'.bam

- Remove params.outputdir from mount and incorporate directly in script.
***/
