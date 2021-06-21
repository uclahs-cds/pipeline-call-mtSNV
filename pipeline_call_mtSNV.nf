/***
Copyright (c) 2021, UCLA JCCC / Laboratory of Pual C. Boutros
'Call-mtSNV' - A Nextflow pipeline for somatic mtSNV (heteroplasmy) calling with NGS data
Writtent by: Takafumi Yamaguchi
Nextflowization: Alfredo Enrique Gonzalez, Andrew Park
***/

//// DSL Version Declaration ////
nextflow.enable.dsl=2

//// Import of Local Modules ////
include { Validate_Inputs                    } from './modules/process/validate_inputs'
include { extract_mtDNA_BAMQL              } from './modules/process/extract_mtDNA_BAMQL'
include { align_mtDNA_MToolBox             } from './modules/process/align_mtDNA_MToolBox'
include { call_mtSNV_mitoCaller              } from './modules/process/call_mtSNV_mitoCaller'
include { convert_mitoCaller2vcf_mitoCaller  } from './modules/process/convert_mitoCaller2vcf_mitoCaller'          
include { call_heteroplasmy                  } from './modules/process/call_heteroplasmy'
include { validate_outputs                   } from './modules/process/validate_outputs'


//// log info  ////
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
        mt_ref = ${params.mt_ref}
        gmapdb = ${params.gmapdb}
        genome_fasta = ${params.genome_fasta}
        reference_genome = ${params.reference_genome_hg38}
    
    - output: x
        temp_dir: ${params.temp_dir}
        output_dir: ${params.output_dir}
        lot_output_dir: ${params.log_output_dir}
      
    - options:
      sample_mode = ${params.sample_mode}
      save_intermediate_files = ${params.save_intermediate_files}
      cache_intermediate_pipeline_steps = ${params.cache_intermediate_pipeline_steps}
      max_number_of_parallel_jobs = ${params.max_number_of_parallel_jobs}

    ------------------------------------
    Starting workflow...
    ------------------------------------
   """
   .stripIndent()

//// Input paths from input.csv ////

  // Conditional for 'paired' sample
if (params.sample_mode == 'paired') {
  Channel
    .fromPath(params.input_csv)
    .ifEmpty { exit 1, "params.input_csv was empty - no input files supplied" }
    .splitCsv(header:true) 
    .flatMap{ row -> tuple(
      row.sample_input_1_type,
      row.sample_input_1_name, 
      row.sample_input_1_path, 
      row.sample_input_2_type,
      row.sample_input_2_name,
      row.sample_input_2_path
      )
      }
    .collate(3)
    .set { input_ch }
    }

  // Codnidtional for 'single' sample
    else if (params.sample_mode == 'single') {
      Channel
    .fromPath(params.input_csv)
    .ifEmpty { exit 1, "params.input_csv was empty - no input files supplied" }
    .splitCsv(header:true) 
    .flatMap{ row -> tuple(
      row.sample_input_1_type,
      row.sample_input_1_name, 
      row.sample_input_1_path
      )
      }
    .collate(3)
    .set { input_ch }

    }
    else {
      throw new Exception('ERROR: params.sample_mode not recognized')
    }

workflow{
 
  //step 1: validation of inputs
  Validate_Inputs( input_ch ) 
  
 //step 2: extraction of mitochondrial reads using BAMQL
  extract_mtDNA_BAMQL( input_ch ) 

  //step 3: remapping reads with mtoolbox
  align_mtDNA_MToolBox(
    extract_mtDNA_BAMQL.out.bams,
    extract_mtDNA_BAMQL.out.sample_name, 
    extract_mtDNA_BAMQL.out.type
    )

  //step 4: variant calling with mitocaller
  call_mtSNV_mitoCaller( 
    align_mtDNA_MToolBox.out.bams,
    align_mtDNA_MToolBox.out.sample_name,  
    align_mtDNA_MToolBox.out.type 
    )

  //step 5: change mitocaller output to vcf
  convert_mitoCaller2vcf_mitoCaller( 
    call_mtSNV_mitoCaller.out.tsv,
    call_mtSNV_mitoCaller.out.sample_name,    
    call_mtSNV_mitoCaller.out.type 
    )

  //step 6: call heteroplasmy script
  if (params.sample_mode == 'paired') {
    call_heteroplasmy( call_mtSNV_mitoCaller.out.gz.toSortedList() )
    }
    
  //step 7: validate output script
  validate_outputs(
    convert_mitoCaller2vcf_mitoCaller
    .out
    .vcf
    .flatten()
  )  
}
