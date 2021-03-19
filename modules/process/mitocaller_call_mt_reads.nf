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
    container 'ubuntu:16.04'
    containerOptions "-v ${params.mt_ref}:/mito_ref/mito_ref.fa/ -v ${params.suplemental_scripts}:/mitocaller2/"
  
    memory amount_of_memory
    cpus number_of_cpus


    publishDir "${params.output_dir}", enabled: true, mode: 'copy'
    label 'mitocaller'

    input:
      file mtoolbox_out //from next_stage_2

    output: 
        
      file("${mtoolbox_out.baseName}_mitocaller.tsv.gz")   
   
    script:
    """
    /mitocaller2/mitoCaller -m -b "${mtoolbox_out}"  -r /mito_ref/mito_ref.fa -v ${mtoolbox_out.baseName}_mitocaller.tsv.gz
    """
}



