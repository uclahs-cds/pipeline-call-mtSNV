/***
Copyright (c) 2021, UCLA JCCC / Laboratory of Paul C. Boutros
'Call-mtSNV' - A Nextflow pipeline for somatic mtSNV (heteroplasmy) calling with NGS data
Written by: Takafumi Yamaguchi
Nextflowization: Alfredo Enrique Gonzalez, Andrew Park
***/

//// DSL Version Declaration ////
nextflow.enable.dsl=2

//// Import of Local Modules ////
include { Validate_Inputs                    } from './module/validation'
include { extract_mtDNA_BAMQL                } from './module/extract_mtDNA_BAMQL'
include { align_mtDNA_MToolBox               } from './module/align_mtDNA_MToolBox'
include { call_mtSNV_mitoCaller              } from './module/call_mtSNV_mitoCaller'
include { convert_mitoCaller2vcf_mitoCaller  } from './module/convert_mitoCaller2vcf_mitoCaller'
include { call_heteroplasmy                  } from './module/call_heteroplasmy'
include { validate_outputs                   } from './module/validation'

log.info """\
======================================
C A L L - M T S N V
======================================
Boutros Lab

    Current Configuration:
    - pipeline:
        name: ${workflow.manifest.name}
        version: ${workflow.manifest.version}

    - input:
        input_csv: ${params.input_csv}
        gmapdb = ${params.gmapdb}
        mt_reference_genome = ${params.mt_ref_genome_dir}

    - output: x
        output_dir: ${params.output_dir}

    - options:
        sample_mode = ${params.sample_mode}
        save_intermediate_files = ${params.save_intermediate_files}
        cache_intermediate_pipeline_steps = ${params.cache_intermediate_pipeline_steps}

    ------------------------------------
    Starting workflow...
    ------------------------------------
    """
    .stripIndent()

// Conditional for 'paired' sample
if (params.sample_mode == 'paired') {
    Channel
        .fromPath(params.input_csv, checkIfExists: true)
        .ifEmpty { exit 1, "params.input_csv was empty - no input files supplied" }
        .splitCsv(header:true)
        .multiMap {
            it ->
            project_id: it.project_id
            sample_id: it.sample_id
            normal_ch: ['normal', it.normal_id, it.normal_BAM]
            tumour_ch: ['tumour', it.tumour_id, it.tumour_BAM]
            }
        .set { input_csv_ch }

    input_csv_ch.normal_ch.mix(input_csv_ch.tumour_ch).set { main_work_ch }
    }

else if (params.sample_mode == 'single') {
    Channel
        .fromPath(params.input_csv)
        .ifEmpty { exit 1, "params.input_csv was empty - no input files supplied" }
        .splitCsv(header:true)
        .multiMap {
            it ->
            project_id: it.project_id
            sample_id: it.sample_id
            single_sample: ['single_sample', it.normal_id, it.normal_BAM]
            }
        .set{ input_csv_ch }

    input_csv_ch.single_sample.set{ main_work_ch }
    }

workflow{

    //step 1: validation of inputs
    Validate_Inputs( main_work_ch )

    //step 2: extraction of mitochondrial reads using BAMQL
    extract_mtDNA_BAMQL( main_work_ch )

    //step 3: remapping reads with mtoolbox
    align_mtDNA_MToolBox( extract_mtDNA_BAMQL.out.extracted_mt_reads )

    //step 4: variant calling with mitocaller
    call_mtSNV_mitoCaller( align_mtDNA_MToolBox.out.aligned_mt_reads )

    //step 5: change mitocaller output to vcf
    convert_mitoCaller2vcf_mitoCaller(  call_mtSNV_mitoCaller.out.mt_variants_tsv )

    //Fork mitoCaller Output
    call_mtSNV_mitoCaller.out.mt_variants_gz.branch{
        normal: it[0] == 'normal'
        tumour: it[0] == 'tumour'
        }
        .set{ mitoCaller_forked_ch }

    // //step 6: call heteroplasmy script
    if (params.sample_mode == 'paired') {
        call_heteroplasmy( mitoCaller_forked_ch.normal, mitoCaller_forked_ch.tumour )
        }

    //step 7: validate output script
    validate_outputs(
        convert_mitoCaller2vcf_mitoCaller
        .out
        .vcf
        .flatten()
        )
    }
