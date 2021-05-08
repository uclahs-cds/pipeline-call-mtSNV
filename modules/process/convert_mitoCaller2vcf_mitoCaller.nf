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

process convert_mitoCaller2vcf_mitoCaller {
    container 'blcdsdockerregistry/mitocaller2vcf:1.0.0'
    publishDir "${params.output_dir}", 
    enabled: true, 
    mode: 'copy',
    saveAs: {"${params.sample_name}/convert_mitoCaller2vcf_mitoCaller/${file(it).getName()}" }
    
 
    //memory proclamation
    memory amount_of_memory
    cpus number_of_cpus

    //logs
    publishDir path: params.output_dir,
    pattern: ".command.*",
    mode: "copy",
    saveAs: {"${params.sample_name}/logs_convert_mitoCaller2vcf_mitoCaller/log${file(it).getName()}" }
    
    input:
      file mitocaller_out 

    output: 
        
      path '*.vcf', emit: vcf
      path '.command.*' 
      path '*.txt'
   
   
    script:
    """
    echo '${mitocaller_out.baseName} ${mitocaller_out}' > ${mitocaller_out.baseName}.list
    python3.8 /mitoCaller2vcf/mitoCaller2vcf.py -s ./${mitocaller_out.baseName}.list -y ${params.sample_name}_homoplasmy.vcf -o ${params.sample_name}.vcf
    ls > files.txt
    """
}



