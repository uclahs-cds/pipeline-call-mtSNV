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
        normal: ${params.input['normal']['BAM']}
        tumour: ${params.input['tumour']['BAM']}
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
        .of(params.input['normal'])
        .map {
            ['normal', it['id'], it['BAM']]
        }
        .set { normal_ch }
    Channel
        .of(params.input['tumour'])
        .map {
            ['tumour', it['id'], it['BAM']]
        }
        .set { tumour_ch }

    normal_ch.mix(tumour_ch).set { main_work_ch }
    }

else if (params.sample_mode == 'single') {
    Channel
        .of(params.input['normal'])
        .map {
            ['normal', it['id'], it['BAM']]
        }
        .set { main_work_ch }
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
