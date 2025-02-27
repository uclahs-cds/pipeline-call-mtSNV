include { run_validate_PipeVal } from '../external/pipeline-Nextflow-module/modules/PipeVal/validate/main.nf' addParams(
        options: [
        docker_image_version: params.pipeval_version,
        main_process: "./", //Save logs in <log_dir>/process-log/run_validate_PipeVal
        validate_extra_args: params.validate_extra_args
        ]
    )

Channel
    .fromList(params.validation_list)
    .set { input_validation }

workflow validate_input {
    main:
    run_validate_PipeVal(input_validation)
    run_validate_PipeVal.out.validation_result.collectFile(
        name: 'input_validation.txt',
        storeDir: "${params.output_dir_base}/validation"
        )
}
