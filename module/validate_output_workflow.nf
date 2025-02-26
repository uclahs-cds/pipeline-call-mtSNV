include { run_validate_PipeVal } from '../external/pipeline-Nextflow-module/modules/PipeVal/validate/main.nf' addParams(
    options: [
        docker_image_version: params.pipeval_version,
        main_process: "./" //Save logs in <log_dir>/process-log/run_validate_PipeVal
        ]
    )

workflow validate_output {
    take:
    vcf_gz
    main:
    run_validate_PipeVal(vcf_gz)
    run_validate_PipeVal.out.validation_result.collectFile(
        name: 'output_validation.txt',
        storeDir: "${params.output_dir_base}/validation"
        )
}