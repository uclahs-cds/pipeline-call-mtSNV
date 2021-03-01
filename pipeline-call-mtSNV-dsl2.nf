/***
Copyright (c) 2021, UCLA JCCC / Laboratory of Pual C. Boutros
'Call-mtSNV' - A Nextflow pipeline for somatic mtSNV (heteroplasmy) calling with NGS data
Writtent by: Takafumi Yamaguchi
Nextflowization: Alfredo Enrique Gonzalez, Andrew Park
***/

//// DSL Version Declaration ////
nextflow.enable.dsl=2


//// Import of Local Modules ////
include { Validate_Inputs           } from './modules/process/validate_inputs'
include { BAMQL_extract_mt_reads    } from './modules/process/bamql_extract_mt_reads'
include { MTOOLBOX_remap_reads      } from './modules/process/mtoolbox_remap_reads'
include { MITOCALLER_call_mt_reads  } from './modules/process/mitocaller_call_mt_reads'
include { Call_Heteroplasmy         } from './modules/process/call_heteroplasmy'


//// log info  ////
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
        mitocaller = ${params.mitocaller}
    
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

    ------------------------------------
    Starting workflow...
    ------------------------------------
   """
   .stripIndent()


//// Input paths from input.csv ////
Channel
    .fromPath(params.input_csv)//params.input_csv)
    .ifEmpty { exit 1, "params.input_csv was empty - no input files supplied" }
    .splitCsv(header:true) 
    .map{ row -> tuple(row.normal, row.tumour) }
    .set { input_ch }



workflow{
  //step 1: validation of inputs
  Validate_Inputs( input_ch ) 
  
  //step 2: extraction of mitochondrial reads using BAMQL
  BAMQL_extract_mt_reads( input_ch ) 

  //step 3: remapping reads with mtoolbox
  MTOOLBOX_remap_reads( BAMQL_extract_mt_reads.out )

  //step 4: variant calling with mitocaller
  MITOCALLER_call_mt_reads(MTOOLBOX_remap_reads.out )

  //step 5: call heteroplasmy script
  Call_Heteroplasmy( MITOCALLER_call_mt_reads.out )

}

/** Future Work 
- Single sample processing

