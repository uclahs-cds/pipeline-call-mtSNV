/***
Copyright (c) 2021, UCLA JCCC / Laboratory of Pual C. Boutros
'Call-mtSNV' - A Nextflow pipeline for somatic mtSNV (heteroplasmy) calling with NGS data
Written by: Takafumi Yamaguchi
Nextflowization: Alfredo Enrique Gonzalez, Andrew Park
***/

//// DSL Version Declaration ////
nextflow.enable.dsl=2

//// Import of Local Modules ////
include { Validate_Inputs                    } from './modules/process/validate_inputs'
include { extract_mtDNA_BAMQL                } from './modules/process/extract_mtDNA_BAMQL'
include { align_mtDNA_MToolBox               } from './modules/process/align_mtDNA_MToolBox'
include { call_mtSNV_mitoCaller              } from './modules/process/call_mtSNV_mitoCaller'
include { convert_mitoCaller2vcf_mitoCaller  } from './modules/process/convert_mitoCaller2vcf_mitoCaller'
include { call_heteroplasmy                  } from './modules/process/call_heteroplasmy'
include { validate_outputs                   } from './modules/process/validate_outputs'

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
        mt_reference_genome = ${params.directory_containing_mt_ref_genome_chrRSRS_files}

    - output: x
        temp_dir: ${params.temp_dir}
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
        .multiMap { it ->
                    project_id: it.project_id
                    sample_id: it.sample_id
                    normal_key: 'normal'
                    normal_id: it.normal_id
                    normal_BAM: it.normal_BAM
                    tumour_key: 'tumour'
                    tumour_id: it.tumour_id
                    tumour_BAM: it.tumour_BAM }
        .set{ input_csv_ch }

    input_csv_ch.normal_key.concat(
            input_csv_ch.normal_id,
            input_csv_ch.normal_BAM,
            input_csv_ch.tumour_key,
            input_csv_ch.tumour_id,
            input_csv_ch.tumour_BAM )
        .collate(3)
        .set{ main_work_ch }
    }

 else if (params.sample_mode == 'single') {
     Channel
        .fromPath(params.input_csv)
        .ifEmpty { exit 1, "params.input_csv was empty - no input files supplied" }
        .splitCsv(header:true)
        .multiMap { it ->
                    project_id: it.project_id
                    sample_id: it.sample_id
                    single_sample_key: 'single_sample'
                    single_sample_id: it.normal_id
                    single_sample_BAM: it.normal_BAM }
        .set{ input_csv_ch }

     input_csv_ch.single_sample_key.concat( input_csv_ch.single_sample_id, input_csv_ch.single_sample_BAM )
        .collate(3)
        .set{ main_work_ch }
 }





      // normal_ch = [ branched_input.normal_key, branched_input.normal_id, branched_input.normal_BAM ]

      // branched_input.mix.multiMap{ it ->
      //   sample_id: it.sample_id
      //   normal_key: 'normal'
      //   normal_id: it.normal_id
      // }
      // .set{ normal_ch }



      // branched_input.collate(2).set{ main_flow_ch}

      // identifiers_ch = branched_input{ it -> it.normal_id + it.normal_BAM}.collect()


    // project_sample_ch = [ branched_input.project_id, branched_input.sample_id ]
    // main = [ [ branched_input.normal_key, branched_input.normal_id, branched_input.normal_BAM ] , [ branched_input.tumour_key, branched_input.tumour_id, branched_input.tumour_BAM ] ]

    // main2ch = main.collate(1)
    // tumour_ch = [ branched_input.tumour_key, branched_input.tumour_id, branched_input.tumour_BAM ]
    // main_ch = normal_ch.mix(tumour_ch)
        // .map{
        //           project_id: it.project_id
        //           sample_id: it.sample_id
        //           normal_fill: 'normal'
        //           normal_id: it.normal_id
    //     //           normal_BAM: it.normal_BAM
    //     //           tumour_id: it.tumour_id
    //     //           tumour_BAM: it.tumour_BAM
    //     //           }
    //     .set{ starting_ch }

    //     starting_ch.project_id.collect.set{ new_ch }

    //     // sample_type_info = [ starting_ch.project_id.first().collect().map{ it -> [project_id: it] }, starting_ch.sample_id ]
    //     // .branch{
    //     //   normal: it == 'normal_id'
    //     //   tumour: it == it.tumour_id
    //     //   normal_BAM: it == it.normal_BAM
    //     // }
    //     // .set { input_ch }
    // }
    // else if (params.sample_mode == 'single') {
    //   Channel
    // .fromPath(params.input_csv)
    // .ifEmpty { exit 1, "params.input_csv was empty - no input files supplied" }
    // .splitCsv(header:true)
    // .flatMap{ row -> tuple(
    //   row.sample_input_1_type,
    //   row.sample_input_1_name,
    //   row.sample_input_1_path
    //   )
    //   }
    // .collate(3)
    // .set { input_ch }
    // }
    // else {
    //   throw new Exception('ERROR: params.sample_mode not recognized')
    // }

workflow{

  //step 1: validation of inputs
  Validate_Inputs( main_work_ch )

 //step 2: extraction of mitochondrial reads using BAMQL
  extract_mtDNA_BAMQL( main_work_ch )

  //step 3: remapping reads with mtoolbox
  align_mtDNA_MToolBox( extract_mtDNA_BAMQL.out.main_output )

  //step 4: variant calling with mitocaller
  call_mtSNV_mitoCaller( align_mtDNA_MToolBox.out.main_output )

  //step 5: change mitocaller output to vcf
  convert_mitoCaller2vcf_mitoCaller(  call_mtSNV_mitoCaller.out.main_output )

  //Fork mitoCaller Output

  call_mtSNV_mitoCaller.out.main_output.branch{
        normal: it[0] == 'normal'
        tumour: it[0] == 'tumour'
  }
  .set{ mitoCaller_forked_ch }

  // //step 6: call heteroplasmy script
  if (params.sample_mode == 'paired') {
    call_heteroplasmy( mitoCaller_forked_ch.normal, mitoCaller_forked_ch.tumour )
    }

    //

  // //step 7: validate output script
  // validate_outputs(
  //   convert_mitoCaller2vcf_mitoCaller
  //   .out
  //   .vcf
  //   .flatten()
  // )
}
