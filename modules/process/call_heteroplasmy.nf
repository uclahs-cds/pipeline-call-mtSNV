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

process call_heteroplasmy {
    container "blcdsdockerregistry/call-mtsnv:call-heteroplasmy-script-1.0"
    containerOptions "-v ${params.heteroplasmy_script}:/script/"
    publishDir "${params.output_dir}", 
    enabled: true, 
    mode: 'copy',
    saveAs: {"${params.run_name}_${params.date}/call_heteroplasmy/${file(it).getName()}" }

    //memory proclamation
    memory amount_of_memory
    cpus number_of_cpus

    // tsv
    publishDir path: params.log_output_dir,
    pattern: "*.tsv",
    mode: "copy",
    saveAs: {"${params.run_name}_${params.date}/call_heteroplasmy/${file(it).getName()}" }


    //logs
    publishDir path: params.log_output_dir,
    pattern: ".command.*",
    mode: "copy",
    saveAs: {"${params.run_name}_${params.date}/logs_call_heteroplasmy/${file(it).getName()}" }

    input:
        tuple( 
        path(normal_mitocaller_out),
        path(tumour_mitocaller_out)
        ) 
    
    output:
        path '*.tsv'
        path '.command.*'


    script:
    """
     perl /script/call_heteroplasmy_mitocaller.pl \
    --normal ${normal_mitocaller_out} \
    --tumour ${tumour_mitocaller_out} \
    --ascat_stat
    ls > list.tsv
    """
}

/*** Future Work 
- Change resource allocation to refer to single module
- make this step optional in the case of single samples
***/
