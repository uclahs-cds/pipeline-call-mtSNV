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
    containerOptions "-v ${params.mito_ref}:/mito_ref/mito_ref.fa/ -v ${params.mitocaller}:/mitocaller2/"
  
    memory amount_of_memory
    cpus number_of_cpus


    publishDir "${params.output_dir}", enabled: true, mode: 'copy'
    label 'mitocaller'

    input:
        tuple(
            path(normal_out_sorted), 
            path(tumor_out_sorted) 
        ) //from next_stage_2

    output: 
        tuple(
        file("${normal_out_sorted.baseName}_mitocaller.tsv.gz"), 
        file("${tumor_out_sorted.baseName}_mitocaller.tsv.gz")
        ) //into next_stage_3 

    script:
    """
    /mitocaller2/mitoCaller -m -b "${normal_out_sorted}"  -r /mito_ref/mito_ref.fa -v ${normal_out_sorted.baseName}_mitocaller.tsv.gz
    /mitocaller2/mitoCaller -m -b "${tumor_out_sorted}"  -r /mito_ref/mito_ref.fa -v ${tumor_out_sorted.baseName}_mitocaller.tsv.gz
    """
}


