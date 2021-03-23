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

process Call_Heteroplasmy {
    container "blcdsdockerregistry/call-heteroplasmy-script:1.0"
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
    saveAs: { "logs_heteroplasmy_script/${file(normal_mitocaller_out).getSimpleName()}/log${file(it).getName()}" } 


    input:
        tuple(
        path(tumour_mitocaller_out), 
        path(normal_mitocaller_out)
        ) 
    
    output:
        file '*.tsv'
        path '.command.*'


    script:
    """
     perl /src/script/call_heteroplasmy_mitocaller.pl \
    --normal ${normal_mitocaller_out} \
    --tumour ${tumour_mitocaller_out} \
    --ascat_stat
    
    mv heteroplasmy_calculation.tsv heteroplasmy_calculation_${tumour_mitocaller_out.baseName}_vs_${normal_mitocaller_out.baseName}    
    """
}

/*** Future Work 
- Change resource allocation to refer to single module
- make this step optional in the case of single samples
***/
