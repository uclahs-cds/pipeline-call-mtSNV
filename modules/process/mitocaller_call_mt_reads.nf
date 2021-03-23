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
    container 'blcdsdockerregistry/mitocaller:1.0.0'
    containerOptions "-v ${params.reference_genome_hg38}:/mito_ref/mito_ref.fa/"
    // Note - reference genome needs to be mounted otherwise mitocaller fails
    publishDir "${params.output_dir}", 
    enabled: true, 
    mode: 'copy'
    label 'mitocaller'
 
    
    //memory proclamation
    memory amount_of_memory
    cpus number_of_cpus

    //logs
    publishDir path: params.log_output_dir,
    pattern: ".command.*",
    mode: "copy",
    saveAs: { "logs_mitocaller/${file(mtoolbox_out).getSimpleName()}/log${file(it).getName()}" } 

    input:
      file mtoolbox_out //from next_stage_2

    output: 
        
      path "${mtoolbox_out.baseName}_mitocaller.tsv.gz", emit: gz
      path '.command.*'
   
   
    script:
    """
    /mitocaller2/mitoCaller -m -b "${mtoolbox_out}"  -r /mito_ref/mito_ref.fa -v ${mtoolbox_out.baseName}_mitocaller.tsv.gz
    """
}



