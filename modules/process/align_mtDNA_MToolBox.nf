process align_mtDNA_MToolBox {
    container params.MToolBox_docker_image
    containerOptions "--volume \"${params.gmapdb}:/src/gmapdb/\" --volume \"${params.directory_containing_mt_ref_genome_chrRSRS_files}:/src/genome_fasta/\""
        label 'process_high'

    // Main ouput recalibrated & reheadered reads
    publishDir {"${params.base_output_dir}/${sample_name}/${params.mtoolbox_version}/output/"},
        pattern: "{OUT_${bamql_out.baseName}/OUT2-sorted.bam,mt_classification_best_results.csv,summary*.txt}",
        mode: 'copy',
        saveAs: {"${params.mtoolbox_version}_${sample_name}_${file(it).getName()}"}

    publishDir {"${params.base_output_dir}/${sample_name}/${params.mtoolbox_version}/intermediate/align_mtDNA_MToolBox/"},
        enabled: params.save_intermediate_files,
        pattern: "OUT_${bamql_out.baseName}",
        mode: 'copy',
        saveAs: {"OUT_${bamql_out.baseName}" }

    publishDir {"${params.base_output_dir}/${sample_name}/${params.mtoolbox_version}/intermediate/align_mtDNA_MToolBox/"},
        enabled: params.save_intermediate_files,
        pattern: "{tmp,VCF_dict_tmp,test}",
        mode: 'copy',
        saveAs: {"${file(it).getName()}" }

    // mtoolbox folder with supplementary files
    publishDir {"${params.base_output_dir}/${sample_name}/${params.mtoolbox_version}/intermediate/align_mtDNA_MToolBox/"},
        enabled: params.save_intermediate_files,
        pattern: "*.{txt,conf,vcf,gz}",
        mode: 'copy',
        saveAs: {"${file(it).getName()}" }

    //logs 
    publishDir "${params.log_output_dir}/process-log/${params.mtoolbox_version}/${task.process.split(':')[-1].replace('_', '-')}/",
        pattern: ".command.*",
        mode: "copy",
        saveAs: {"log${file(it).getName()}" }

    input:
    tuple(
      val(type),
      val(sample_name),
      path(bamql_out)
      )

    output:
     tuple val(type), val(sample_name), path("OUT_${bamql_out.baseName}/OUT2-sorted.bam"), emit: aligned_mt_reads

      path '.command.*'
      path("OUT_${bamql_out.baseName}")
      path("*.csv")
      path("*.txt")
      path("*.gz")
      path("*.vcf")
      path("VCF_dict_tmp")
      path("tmp")
      path("*.conf")

// !!!NOTE!!! Output file location can not be spceified withing the mtoolbox command or it breaks mtoolbox script when running a BAM file
// !!!NOTE!!! Location of the directory with the reference genome needs to be mounted on docker image. The actual file can not be called on. This is because MToolBox uses a script as an input that requires this file location.

  script:
  """
  printf "input_type='bam'\nref='RSRS'\ninput_path=${bamql_out}\ngsnapdb=/src/gmapdb/\nfasta_path=/src/genome_fasta/\n" > config_'${bamql_out.baseName}'.conf

  MToolBox.sh -i config_'${bamql_out.baseName}'.conf -m '-t ${task.cpus}'

  """
}