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
def docker_image_sha512sum = "blcdsdockerregistry/align-dna:sha512sum-1.0"

// resource information
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


/*
 *  Defines the reads channel 
 */

Channel
    .fromPath(params.input_csv)//params.input_csv)
    .ifEmpty { exit 1, "params.input_csv was empty - no input files supplied" }
    .splitCsv(header:true) 
    .map{ row -> tuple(row.type, row.normal, row.tumour) }
    .set { input_ch }

//query = Channel.from('query')

// get the query from param

Channel
   .from(params.query)
   .ifEmpty { error "Cannot find bamql query: ${params.query}" }
   .set { input_ch_mt_reads_extraction_query }


/**********
 * PART 1: Extract MT reads
 *
 * Process 1: Use bamql to extract reads mapped to mitochondria genome in the input BAM (hg19/GRCh37)
 * This stage is quite fast and memory efficient (it only takes a few min to process one BAM)
 */

// Extract reads with bamql
process extract_reads { 
  container 'blcdsdockerregistry/call-mtsnv:bamql-1.5.1'
  containerOptions "--volume ${params.temp_dir}:/tmp"
  publishDir "${params.bamql_out_dir}", enabled: true, mode: 'copy'
 tag "Extract MT Reads"
 
  input:
    tuple(val(type), path(normal), path(tumour)) from input_ch
    each params.query from input_ch_mt_reads_extraction_query
    //
  output: 
    tuple(
     file("'${normal.baseName}'_'${type}'_mt.bam"),
     file("${tumour.baseName}'_'${type}'_mt.bam")
     )into next_stage
  
  script:
  """
bamql -b -o '${normal.baseName}'_'${type}'_mt.bam -f '${normal}' '${params.query}'
bamql -b -o '${tumour.baseName}'_'${type}'_mt.bam -f '${tumour}' '${params.query}'
  """
}
/**********
 * PART 2: MToolBox
 * Process 1: Run MToolBox.sh on the BAMs generated in the ExtractReads stage. 
 * MToolBox remaps the reads to RCRS or RSRS mt genome. Current default is RSRS.
 * This stage is a bit memory intensive and requires 4 cores * 13G as default. 
 * You can change the number of cores and memory in the stage parameter YAML.
 * This stage takes a few hours depending on the BAM file size.
 bamql -b -o ${normal.baseName}_${type}_mt.bam -f ${normal} '${params.query}' \
bamql -b -o ${tumour.baseName}_${type}_mt.bam -f ${tumour} '${params.query}'


*/



process mtoolbox {
  container docker_image_mtoolbox // TODO: rename the tag to 1.0.0
  containerOptions "--volume ${params.output_dir}:/src/imported/"
  
  //containerptions "-v ${params.mtoolbox_out}:${params.rsrs_out} -v ${params.output_dir}:${params.extract_reads_out}"
  publishDir "${params.mtoolbox_out_dir}", enabled: true, mode: 'copy'
  label 'MToolBox'

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

//  file bam from next_stage

// Comment on script directory setup
//
  script:
  """

  mkdir OUT_${extracted_normal_reads}_mtoolbox_out
  mkdir OUT_${extracted_tumor_reads}_mtoolbox_out
  
  printf "input_type='bam'\nref='RSRS'\ninput_path=${extracted_normal_reads}\n" > config4.conf
  printf "input_type='bam'\nref='RSRS'\ninput_path=${extracted_tumor_reads}\n" > config5.conf
  
  MToolBox.sh -i config4.conf -m '-t 4'
  MToolBox.sh -i config5.conf -m '-t 4'
  mv OUT_${extracted_normal_reads}_mtoolbox_out/OUT2-sorted.bam OUT_${extracted_normal_reads.baseName}.bam
  mv OUT_${extracted_tumor_reads}_mtoolbox_out/OUT2-sorted.bam OUT_${extracted_tumor_reads.baseName}.bam

  """
}

// OUT_${extracted_normal_reads}_mtoolbox_out/OUT2.sorted.bam
process mitocaller {
    container docker_image_mitocaller
    containerOptions "-v ${params.mito_ref}:/reference/ -v ${params.mitocaller_out_dir}:/output/ -v ${params.output_dir}:/mtoolbox/"

    publishDir "${params.mitocaller_out_dir}", enabled: true, mode: 'copy'
    label 'mitocaller'

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


/*
 *  END OF PART 2


  MToolBox.sh -i /src/imported/config1.sh -m '-t 4' > "${extracted_normal_reads}_mtoolbox_out"
  MToolBox.sh -i /src/imported/config2.sh -m '-t 4' > "${extracted_tumor_reads}_mtoolbox_out"

 printf "input_type='file1_type'\nref='file_ref_type'\ninput_path='extractedreads_path'\noutput_name='extractedreads_mtoolbox_out_1'\n" > config_t.sh

printf "input_type=bam\nref=${params.mt_ref_type}\ninput_path='${extracted_reads}'\noutput_name=${extracted_reads}'_mtoolbox_out_1'\n" > /src/MToolBox-master/MToolBox/config.sh

printf "input_type=bam\nref=RSRS\ninput_path=/tmp/01_pipeline/03_outputs/04_temp/99/8aab29ab1118bf1a1c643ffe21fc38/151e3fac-7231-5708-a849-b5fefe3ea2a1_wgs_gdc_realn_normal_mt.bam\noutput_name=extractedreads_mtoolbox_out_1\n" > config_t.sh

 printf "input_type='bam'\nref='RSRS'\ninput_path='${extracted_reads}'\noutput_name=${extracted_reads}'_mtoolbox_out_1'\n" > /src/MToolBox-master/config.sh

printf "input_type='fastq'\nref='RCRS'\ninput_path='/src/MToolBox-master/MToolBox/test1'\noutput_name=/src/MToolBox-master/MToolBox/test1/HG00119\nlist='HG00119.lst'\nmtdb_fasta='chrM.fa'\nhg19_fasta='hg19RCRS.fa'\nmtdb='chrM'\nhumandb='hg19RCRS'\n" > config.sh
 
 printf "input_type=fastq\nref=RCRS\ninput_path=/src/imported/\noutput_name=/src/imported/HG00119\nlist=HG00119.lst\nmtdb_fasta=chrM.fa\nhg19_fasta=hg19RCRS.fa\nmtdb=chrM\nhumandb=hg19RCRS\n" > config.sh
  ##pushd /src/MToolBox


printf "input_type=${params.input_file_type}\nref=${plsarams.mt_ref_type}\ninput_path=/tmp/01_pipeline/03_outputs/04_temp/99/8aab29ab1118bf1a1c643ffe21fc38/\noutput_name=${extracted_reads}'_mtoolbox_out_1'\n" > /src/MToolBox/config.sh
 *********/



/**********
 * PART 3: mitoCaller
 *
 * Process 1:.mitoCaller will be run on the GSNAP-ed BAMs generated by MToolBox.
 * It takes a few hours depending on the BAM file size.
*/

/*
process mitocaller {
  container "blcdsdockerregistry/mitocaller:1.0"

  containerOptions "-v ${params.mito_ref}:/reference/ -v ${params.mitocaller_out}:/output/ -v ${params.mtoolbox_out}:/mtoolbox/"

  script:
  """
  mitoCaller -m -b /mtoolbox/OUT_CPCG0196-B1_realigned_recalibrated_merged/OUT2-sorted.bam  -r /reference/chrRSRS.fasta -v /output/CPCG0196-B1_mitocaller.tsv.gz
  """
}

*/

/*
 *  END OF PART 3
 *********/

/**********
 * PART 4: call heteroplasmy
 *
 * CallHeteroplasmyh.Compute heteroplasmy from the mitoCaller outputs.i. It only takes a few min.
 * Thresholds ( min_coverage: 100, heteroplasmy_fraction_diff: 0.2) were decided based on Julia's work and can be configured in the stage parameter YAML.
*/

/*
process '1D_prepare_vcf_file' {
  tag "$variantsFile.baseName"

  input: 
    path variantsFile from params.variants
    path blacklisted from params.blacklist

  output:
    tuple \
      path("${variantsFile.baseName}.filtered.recode.vcf.gz"), \
      path("${variantsFile.baseName}.filtered.recode.vcf.gz.tbi") into prepared_vcf_ch
  
  script:  
  """
  vcftools --gzvcf $variantsFile -c \
           --exclude-bed ${blacklisted} \
           --recode | bgzip -c \
           > ${variantsFile.baseName}.filtered.recode.vcf.gz
  tabix ${variantsFile.baseName}.filtered.recode.vcf.gz
  """
}
*/


///// LEFTOVER CODE

/*
bamql command for above after debugging
#if [ "$( docker container inspect -f '{{.State.Status}}' blcdsdockerregistry/bamql:1.7 )" == "running" ]; then echo "True"
# ${input_bam.baseName}-${type}-mt.bam = 'Hello World'
# bamql -b \
      -o ${input_bam.baseName}-${type}-mt.bam \
      -f ${input_bam} \
      '(chr(M) & mate_chr(M)) | (chr(Y) & after(59000000) & mate_chr(M))' 

bamql -b \
      -o ${input_bam.baseName}-${type}-mt.bam \
      -f ${input_bam} \
      ' ${params.query} '
  


*/
/*
 *  END OF PART 1
 *********/

