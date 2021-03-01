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



process Call_Heteroplasmy {
    //Memory Allocation//
    memory amount_of_memory
    cpus number_of_cpus
    
    //Docker Images//
    container "blcdsdockerregistry/call-mtsnv:call-heteroplasmy-script-1.0"


    //Mounted Folders//
    /// 1) perl heteroplasmy script 2) output directory
    containerOptions "-v ${params.heteroplasmy_script}:/script/ -v ${params.haplotype_out_dir}:/output/"

    //Publishing Directory//
    publishDir "${params.haplotype_out_dir}", enabled: true, mode: 'copy'

    input:
        tuple(
        path(normal_mitocaller_out), 
        path(tumour_mitocaller_out)
        ) 
    
    output:
        file '*.tsv'

    script:
    """
     perl /script/call_heteroplasmy_mitocaller.pl \
    --normal ${normal_mitocaller_out} \
    --tumour ${tumour_mitocaller_out} \
    --ascat_stat
    
    """
}