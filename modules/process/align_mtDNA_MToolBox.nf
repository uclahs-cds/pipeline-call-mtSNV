process align_mtDNA_MToolBox {
    container "${params.MToolBox_docker_image}"
    containerOptions "--volume ${params.gmapdb}:/src/gmapdb/ --volume ${params.directory_containing_mt_ref_genome_chrRSRS_files}:/src/genome_fasta/ "
    label 'process_high'
    
    // Main ouput recalibrated & reheadered reads
    publishDir params.output_dir, 
        pattern: "OUT_${bamql_out.baseName}/${sample_name}_mtoolbox_OUT2-sorted.bam",
        mode: 'copy',
        saveAs: {"${params.run_name}_${params.date}/align_mtReads_MToolBox/${sample_name}/${file(it).getName()}" }
    
    // mtoolbox folder with supplementary files
    publishDir params.output_dir, 
        enabled: params.save_intermediate_files,
        pattern: "*.txt",
        mode: 'copy',
        saveAs: {"${params.run_name}_${params.date}/align_mtReads_MToolBox/${sample_name}/${file(it).getName()}" }
    
    publishDir params.output_dir, 
        enabled: params.save_intermediate_files,
        pattern: "OUT_${bamql_out.baseName}",
        mode: 'copy',
        saveAs: {"${params.run_name}_${params.date}/align_mtReads_MToolBox/${sample_name}/OUT_${bamql_out.baseName}" }

    publishDir params.output_dir, 
        enabled: params.save_intermediate_files,
        pattern: "tmp",
        mode: 'copy',
        saveAs: {"${params.run_name}_${params.date}/align_mtReads_MToolBox/${sample_name}/${file(it).getName()}" }

    publishDir params.output_dir, 
        enabled: params.save_intermediate_files,
        pattern: "*.conf",
        mode: 'copy',
        saveAs: {"${params.run_name}_${params.date}/align_mtReads_MToolBox/${sample_name}/${file(it).getName()}" }    

    publishDir params.output_dir, 
        enabled: params.save_intermediate_files,
        pattern: "*.csv",
        mode: 'copy',
        saveAs: {"${params.run_name}_${params.date}/align_mtReads_MToolBox/${sample_name}/${file(it).getName()}" }

    publishDir params.output_dir, 
        enabled: params.save_intermediate_files,
        pattern: "*.vcf",
        mode: 'copy',
        saveAs: {"${params.run_name}_${params.date}/align_mtReads_MToolBox/${sample_name}/${file(it).getName()}" }
 
    publishDir params.output_dir, 
        enabled: params.save_intermediate_files,
        pattern: "*.gz",
        mode: 'copy',
        saveAs: {"${params.run_name}_${params.date}/align_mtReads_MToolBox/${sample_name}/${file(it).getName()}" }

    publishDir params.output_dir, 
        enabled: params.save_intermediate_files,
        pattern: "VCF_dict_tmp",
        mode: 'copy',
        saveAs: {"${params.run_name}_${params.date}/align_mtReads_MToolBox/${sample_name}/${file(it).getName()}" }

    publishDir params.output_dir, 
        enabled: params.save_intermediate_files,
        pattern: "test",
        mode: 'copy',
        saveAs: {"${params.run_name}_${params.date}/align_mtReads_MToolBox/${sample_name}/${file(it).getName()}" }
              
    //logs
    publishDir path: params.output_dir,
        pattern: ".command.*",
        mode: "copy",
        saveAs: {"${params.run_name}_${params.date}/log/align_mtReads_MToolBox/log${file(it).getName()}" }

    input:
      path bamql_out
      val sample_name
      val type

    output: 
      path "OUT_${bamql_out.baseName}/${sample_name}_mtoolbox_OUT2-sorted.bam", emit: bams
      val sample_name, emit: sample_name
      val type, emit: type
      
      //file 'test'
      //val $type, emit: type
      path '.command.*'
      path("OUT_${bamql_out.baseName}")
      //path("intermediate_files.zip")
      path("contents.txt")
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
  mv ./${bamql_out} ./'${bamql_out.baseName}.bam'

  printf "input_type='bam'\nref='RSRS'\ninput_path=${bamql_out}\ngsnapdb=/src/gmapdb/\nfasta_path=/src/genome_fasta/\n" > config_'${bamql_out.baseName}'.conf
  
  MToolBox.sh -i config_'${bamql_out.baseName}'.conf -m '-t ${task.cpus}'

  mv OUT_${bamql_out.baseName}/OUT2-sorted.bam OUT_${bamql_out.baseName}/${sample_name}_mtoolbox_OUT2-sorted.bam

  ls > contents.txt
  """
}