#!/usr/bin/env nextflow 

/*
 * Copyright (c) 2020, UCLA JCCC
 * 'Call-mtSNV' - A Nextflow pipeline for somatic mtSNV (heteroplasmy) calling with NGS data
 * 
 * Takafumi Yamaguchi
 * Andrew Park
 * Alfredo Enrique Gonzalez
 * Paul Boutros
 */
// NOTE- docker images have not been pushed to docker hub yet. They will need to be changed once on cluster

def docker_image_validate_params = "blcdsdockerregistry/align-dna:sha512sum-1.0"
def docker_image_bamql = "blcdsdockerregistry/call-mtsnv:bamql-1.5.1"
def docker_image_mtoolbox = "blcdsdockerregistry/call-mtsnv:mtoolbox-1.0.5"
def docker_image_mitocaller = "blcdsdockerregistry/call-mtsnv:mitocaller-1.0.1"
def docker_image_vcf_tools = "biocontainers/vcftools:v0.1.16-1-deb_cv1"
def docker_image_sha512sum = "blcdsdockerregistry/align-dna:sha512sum-1.0"

// resource information
// resource information
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


/* 


def number_of_cpus = (int) (Runtime.getRuntime().availableProcessors() / params.max_number_of_parallel_jobs)
if (number_of_cpus < 1) {
    number_of_cpus = 1
} 

*/
/*
def amount_of_memory = ((int) (((java.lang.management.ManagementFactory.getOperatingSystemMXBean()
    .getTotalPhysicalMemorySize() / (1024.0 * 1024.0 * 1024.0)) * 0.9) / params.max_number_of_parallel_jobs ))
if (amount_of_memory < 1) {
    amount_of_memory = 1
}
amount_of_memory = amount_of_memory.toString() + " GB"
*/

/*
 * Default parameters should be defined in config
 */

log.info """\
======================================
P I P E L I N E -  M T S N V  v 1.0
======================================
Boutros Lab

   Current Configuration:
    - input: 
        sample_name: ${params.sample_name}
        input_csv: ${params.input_csv}
        mt_ref = ${params.mt_ref}
        mito_ref = ${params.mito_ref}
        query = ${params.query}
        reference_fasta: ${params.reference_fasta}
        reference_fasta_dict: ${params.reference_fasta_dict}
        reference_fasta_index_files: ${params.reference_fasta_index_files}

    - output: x
        temp_dir: ${params.temp_dir}
        output_dir: ${params.output_dir}
        bamql_out_dir: ${params.bamql_out_dir}
        mtoolbox_out_dir: ${params.mtoolbox_out_dir}
        mitocaller_out_dir: ${params.mitocaller_out_dir}
        haplotype_out_dir: ${params.haplotype_out_dir}
      
    - options:
      save_intermediate_files = ${params.save_intermediate_files}
      cache_intermediate_pipeline_steps = ${params.cache_intermediate_pipeline_steps}
      max_number_of_parallel_jobs = ${params.max_number_of_parallel_jobs}

    Tools Used:
    - Bamql: ${docker_image_bamql}
    - mToolBox: ${docker_image_mtoolbox}
    - mitocaller: ${docker_image_mitocaller}
    - sha512sum: ${docker_image_sha512sum}
    - validate_params: ${docker_image_validate_params}
    - validate_params: ${docker_image_validate_params}

    ------------------------------------
    Starting workflow...
    ------------------------------------
   """
   .stripIndent()

// input.csv
Channel
    .fromPath(params.input_csv)//params.input_csv)
    .ifEmpty { exit 1, "params.input_csv was empty - no input files supplied" }
    .splitCsv(header:true) 
    .map{ row -> tuple(row.type, file(row.normal), file(row.tumour)) }
    .set { input_ch }

// query imput for mtoolbox
Channel
   .from('query')
   .ifEmpty { error "Cannot find bamql query: ${params.query}" }
   .set { input_ch_mt_reads_extraction_query }


/**********
 * PART 1: Extract MT reads
 *
 * Process 1: Use bamql to extract reads mapped to mitochondria genome in the input BAM (hg19/GRCh37)
 * This stage is quite fast and memory efficient (it only takes a few min to process one BAM)
 *
 */

// Extract reads with bamql
process extract_reads { 
  container 'blcdsdockerregistry/call-mtsnv:bamql-1.5.1'
  containerOptions "--volume ${params.temp_dir}:/tmp"
  publishDir "${params.bamql_out_dir}", enabled: true, mode: 'copy'

  memory amount_of_memory
  cpus number_of_cpus

  input:
    tuple(val(type), path(normal)) from input_ch
    each params.query from input_ch_mt_reads_extraction_query
  
  output: 
   /** tuple(
     file("${normal.baseName}_${type}_mt.bam"),
     file("${tumour.baseName}_${type}_mt.bam")
     )into next_stage
     */
  
  script:
  """
  bamql -b -o '${normal.baseName}'_'${type}'_mt.bam -f '${normal}' '${params.query}'
  
  """
}

/**
Commands to put in after testing 
input:
   tuple(val(type), path(normal), path(tumour)) from input_ch

script:
  bamql -b -o '${tumour.baseName}'_'${type}'_mt.bam -f '${tumour}' '${params.query}'

**/
/**********
 * PART 2: MToolBox
 * Process 1: Run MToolBox.sh on the BAMs generated in the ExtractReads stage. 
 * MToolBox remaps the reads to RCRS or RSRS mt genome. Current default is RSRS.
 * This stage is a bit memory intensive and requires 4 cores * 13G as default. 
 * You can change the number of cores and memory in the stage parameter YAML.
 * This stage takes a few hours depending on the BAM file size.
*/

/**
process mtoolbox {
  container docker_image_mtoolbox // TODO: rename the tag to 1.0.0
  containerOptions "--volume ${params.output_dir}:/src/imported/"
  
  //containerptions "-v ${params.mtoolbox_out}:${params.rsrs_out} -v ${params.output_dir}:${params.extract_reads_out}"
  publishDir "${params.mtoolbox_out_dir}", enabled: true, mode: 'copy'

   memory amount_of_memory
   cpus number_of_cpus

  //  input:
  input:
    tuple(
        path(extracted_normal_reads),
        path(extracted_tumor_reads),
    )from next_stage

  output: 
        tuple(
        file("OUT_${extracted_normal_reads.baseName}.bam"), 
        file("OUT_${extracted_tumor_reads.baseName}.bam")
        ) into next_stage_2 

// !!!NOTE!!! Output file location can not be spceified or it breaks mtoolbox script when running a BAM file
// explicitly write script commands "i" = "input" etc..
// add dash and a line for each command for readability 
// Use mktemp-d over mkdir when all possible 
  script:
  """

  mkdir OUT_${extracted_normal_reads}_mtoolbox_out
  mkdir OUT_${extracted_tumor_reads}_mtoolbox_out
  
  printf "input_type='bam'\nref='RSRS'\ninput_path=${extracted_normal_reads}\n" > config4.conf
  printf "input_type='bam'\nref='RSRS'\ninput_path=${extracted_tumor_reads}\n" > config5.conf
  
  MToolBox.sh -i config4.conf -m '-t ${task.cpus}'
  MToolBox.sh -i config5.conf -m '-t ${task.cpus}'

  mv OUT_${extracted_normal_reads}_mtoolbox_out/OUT2-sorted.bam OUT_${extracted_normal_reads.baseName}.bam
  mv OUT_${extracted_tumor_reads}_mtoolbox_out/OUT2-sorted.bam OUT_${extracted_tumor_reads.baseName}.bam

  """
}

// OUT_${extracted_normal_reads}_mtoolbox_out/OUT2.sorted.bam
process mitocaller {
    container docker_image_mitocaller
    containerOptions "-v ${params.mito_ref}:/reference/ -v ${params.mitocaller_out_dir}:/output/ -v ${params.output_dir}:/mtoolbox/"

    publishDir "${params.mitocaller_out_dir}", enabled: true, mode: 'copy'

    input:
        tuple(
            path(normal_out_sorted), 
            path(tumor_out_sorted) 
        ) from next_stage_2

    output: 
        tuple(
        file("${normal_out_sorted.baseName}_mitocaller.tsv.gz"), 
        file("${tumor_out_sorted.baseName}_mitocaller.tsv.gz")
        ) into next_stage_3 

    script:
    """
    mitoCaller -m -b ${normal_out_sorted}  -r /reference/chrRSRS.fasta -v ${normal_out_sorted.baseName}_mitocaller.tsv.gz
    mitoCaller -m -b ${tumor_out_sorted}  -r /reference/chrRSRS.fasta -v ${tumor_out_sorted.baseName}_mitocaller.tsv.gz


    """
}


/****

process call_heteroplasmy {
    container vcftools
    containerOptions "-v ${params.mito_ref}:/reference/ -v ${params.mitocaller_out_dir}:/output/ -v ${params.output_dir}:/mtoolbox/"

    publishDir "${params.mitocaller_out_dir}", enabled: true, mode: 'copy'
    label 'mitocaller'

    input:
        tuple(
            path(normal_out_sorted), 
            path(tumor_out_sorted) 
        ) from next_stage_3

    output: 
        tuple(
        file("${normal_out_sorted.baseName}_mitocaller.tsv.gz"), 
        file("${tumor_out_sorted.baseName}_mitocaller.tsv.gz")
        ) into next_stage_3 

    script:
    """
    mitoCaller -m -b ${normal_out_sorted}  -r /reference/chrRSRS.fasta -v ${normal_out_sorted.baseName}_mitocaller.tsv.gz
    mitoCaller -m -b ${tumor_out_sorted}  -r /reference/chrRSRS.fasta -v ${tumor_out_sorted.baseName}_mitocaller.tsv.gz

    """
}

*/
