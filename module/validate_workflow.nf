include { run_validate_PipeVal } from '../external/pipeline-Nextflow-module/modules/PipeVal/validate/main.nf' addParams(
        options: [
        docker_image_version: params.pipeval_version,
        main_process: "./", //Save logs in <log_dir>/process-log/run_validate_PipeVal
        validate_extra_args: params.validation_type == 'input' ? params.validate_extra_args: ''
        ]
    )

workflow validate {
    take:
    files_to_validate
    main:
    run_validate_PipeVal(files_to_validate)
    run_validate_PipeVal.out.validation_result.collectFile(
        name: "${params.validation_type}_validation.txt",
        storeDir: "${params.output_dir_base}/validation"
        )
}
