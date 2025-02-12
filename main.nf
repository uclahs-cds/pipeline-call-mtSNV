/***
Copyright (c) 2021, UCLA JCCC / Laboratory of Paul C. Boutros
'Call-mtSNV' - A Nextflow pipeline for somatic mtSNV (heteroplasmy) calling with NGS data
Written by: Takafumi Yamaguchi
Nextflowization: Alfredo Enrique Gonzalez, Andrew Park
***/
//// DSL Version Declaration ////
nextflow.enable.dsl=2

//// Import of Local Modules ////
include { run_validate_PipeVal as validate_input } from './external/pipeline-Nextflow-module/modules/PipeVal/validate/main.nf' addParams(
        options: [
        docker_image_version: params.pipeval_version,
        main_process: "./", //Save logs in <log_dir>/process-log/run_validate_PipeVal
        validate_extra_args: params.validate_extra_args
        ]
    )
include { extract_mtDNA                      } from './module/extract_mtDNA_workflow.nf'
include { align_mtDNA                        } from './module/align_mtDNA_MToolBox_workflow'
include { call_mtSNV                         } from './module/call_mtSNV_mitoCaller_workflow'
include { run_validate_PipeVal as validate_output } from './external/pipeline-Nextflow-module/modules/PipeVal/validate/main.nf' addParams(
    options: [
        docker_image_version: params.pipeval_version,
        main_process: "./" //Save logs in <log_dir>/process-log/run_validate_PipeVal
        ]
    )

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
        ${params.input_string}
        gmapdb = ${params.gmapdb}
        mt_reference_genome = ${params.mt_ref_genome_dir}
        cram_reference_genome = ${params.cram_reference_genome}

    - output:
        output_dir: ${params.output_dir_base}

    - options:
        sample_mode = ${params.sample_mode}
        save_intermediate_files = ${params.save_intermediate_files}
        cache_intermediate_pipeline_steps = ${params.cache_intermediate_pipeline_steps}

    ------------------------------------
    Starting workflow...
    ------------------------------------
    """
    .stripIndent()

Channel
    .fromList(params.input_list)
    .set { ich }

Channel
    .fromList(params.validation_list)
    .set { input_validation }

workflow{
    validate_input(input_validation)
    validate_input.out.validation_result.collectFile(
        name: 'input_validation.txt',
        storeDir: "${params.output_dir_base}/validation"
        )

    extract_mtDNA(ich)

    align_mtDNA(extract_mtDNA.out.extracted_mt_reads)

    call_mtSNV(align_mtDNA.out.bam_for_mitoCaller)

    validate_output(call_mtSNV.out.vcf_gz)
    validate_output.out.validation_result.collectFile(
        name: 'output_validation.txt',
        storeDir: "${params.output_dir_base}/validation"
        )
    }
