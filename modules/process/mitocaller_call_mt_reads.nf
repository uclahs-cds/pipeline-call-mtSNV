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

process MITOCALLER_call_mt_reads {
    container 'blcdsdockerregistry/mitocaller:1.0_chmod'
    containerOptions "-v ${params.mt_ref}:/mitocaller2/mito_ref.fa/"
    // Note - reference genome needs to be mounted otherwise mitocaller fails
    publishDir "${params.output_dir}", 
    enabled: true, 
    mode: 'copy',
    saveAs: {"${params.sample_name}/mitocaller_out/${file(it).getName()}" }
    
 
    
    //memory proclamation
    memory amount_of_memory
    cpus number_of_cpus

    //logs
    publishDir path: params.output_dir,
    pattern: ".command.*",
    mode: "copy",
    saveAs: {"${params.sample_name}/logs_mitocaller/log${file(it).getName()}" }
    
    input:
      file mtoolbox_out 

    output: 
        
      path "${params.sample_name}_mitocaller.tsv", emit: tsv
      path '.command.*' 
      path '*.txt'
   
   
    script:
    """
    
    /mitocaller2/mitoCaller -m -b "${mtoolbox_out}"  -r /mitocaller2/mito_ref.fa -v ${params.sample_name}_mitocaller.tsv

    ls > files.txt

    """
}



