/***
Copyright (c) 2021, UCLA JCCC / Laboratory of Paul C. Boutros
'Call-mtSNV' - A Nextflow pipeline for somatic mtSNV (heteroplasmy) calling with NGS data
Written by: Takafumi Yamaguchi
Nextflowization: Alfredo Enrique Gonzalez, Andrew Park
***/

//// DSL Version Declaration ////
nextflow.enable.dsl=2

//// Import of Local Modules ////
include { indexFile } from './external/pipeline-Nextflow-module/modules/common/indexFile/main.nf'
include { run_validate_PipeVal as validate_input; run_validate_PipeVal as validate_output } from './external/pipeline-Nextflow-module/modules/PipeVal/validate/main.nf' addParams(
    options: [
        docker_image_version: params.pipeval_version,
        main_process: "./" //Save logs in <log_dir>/process-log/run_validate_PipeVal
        ]
    )
include { extract_mtDNA_BAMQL                } from './module/extract_mtDNA_BAMQL'
include { align_mtDNA_MToolBox               } from './module/align_mtDNA_MToolBox'
include { call_mtSNV_mitoCaller              } from './module/call_mtSNV_mitoCaller'
include { convert_mitoCaller2vcf_mitoCaller  } from './module/convert_mitoCaller2vcf_mitoCaller'
include { call_heteroplasmy                  } from './module/call_heteroplasmy'


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

    - output: x
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
    .fromList(params.input_channel_list)
    .map { it ->
        [
        it.sample_type,
        it.sample_id,
        it.data_path,
        indexFile(it.data_path)
        ]
    }
    .set { ich }

Channel
    .fromList(params.input_channel_list)
    .flatMap { it ->
        [
        it.data_path,
        indexFile(it.data_path)
        ]
    }
    .set { input_validation }

workflow{
    //step 1: validation of inputs
    validate_input(input_validation)
    // Collect and store input validation output
    validate_input.out.validation_result.collectFile(
        name: 'input_validation.txt',
        storeDir: "${params.output_dir_base}/validation"
        )

    //step 2: extraction of mitochondrial reads using BAMQL
    if (params.input_type == 'BAM') {
        extract_mtDNA_BAMQL(ich)
        extracted_mt_reads = extract_mtDNA_BAMQL.out.extracted_mt_reads
    }
    else { // input_type == CRAM
        extract_mtDNA_SAMtools(ich)
        extracted_mt_reads = extract_mtDNA_SAMtools.out.extracted_mt_reads
    }
    //step 3: remapping reads with mtoolbox
    align_mtDNA_MToolBox( extracted_mt_reads )

    //step 4: variant calling with mitocaller
    call_mtSNV_mitoCaller( align_mtDNA_MToolBox.out.aligned_mt_reads )

    //step 5: change mitocaller output to vcf
    convert_mitoCaller2vcf_mitoCaller(  call_mtSNV_mitoCaller.out.mt_variants_tsv )

    //Fork mitoCaller Output
    call_mtSNV_mitoCaller.out.mt_variants_gz.branch{
        normal: it[0] == 'normal'
        tumor: it[0] == 'tumor'
        }
        .set{ mitoCaller_forked_ch }

    // //step 6: call heteroplasmy script
    if (params.sample_mode == 'paired') {
        call_heteroplasmy( mitoCaller_forked_ch.normal, mitoCaller_forked_ch.tumor )
        }

    //step 7: validate output script
    validate_output(
        convert_mitoCaller2vcf_mitoCaller
        .out
        .vcf
        .flatten()
        )
    validate_output.out.validation_result.collectFile(
        name: 'output_validation.txt',
        storeDir: "${params.output_dir_base}/validation"
        )
    }
