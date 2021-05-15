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

process call_mtSNV_mitoCaller {
    container 'blcdsdockerregistry/mitocaller:1.0.0'
    containerOptions "-v ${params.mt_ref}:/mitocaller2/mito_ref.fa/"
    // Note - reference genome needs to be mounted otherwise mitocaller fails
    publishDir "${params.output_dir}", 
    enabled: true, 
    mode: 'copy',
    saveAs: {"${params.run_name}_${params.date}/call_mtSNV_mitoCaller/${sample_name}/${file(it).getName()}" }
    
 
    
    //memory proclamation
    memory amount_of_memory
    cpus number_of_cpus

    //logs
    publishDir path: params.output_dir,
    pattern: ".command.*",
    mode: "copy",
    saveAs: {"${params.run_name}_${params.date}/logs_call_mtSNV_mitoCaller/log${file(it).getName()}" }
    
    input:
      file mtoolbox_out
      val sample_name 
      val type

    output: 
        
      path "${type}_${sample_name}_mitocaller.tsv", emit: tsv
      val sample_name, emit: sample_name
      val type, emit: type
      path '.command.*' 
      path '*.txt'
   
    script:
     //this statement is essential to track identity of file i.e. tumor, normal
    """
    
    /mitocaller2/mitoCaller -m -b "${mtoolbox_out}"  -r /mitocaller2/mito_ref.fa -v ${type}_${sample_name}_mitocaller.tsv

    ls > files.txt

    """
}



