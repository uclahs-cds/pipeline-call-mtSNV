# Boutros Lab call-mtSNV pipeline

 [Boutros Lab call-mtSNV pipeline](#Boutros-Lab-call-mtSNV-pipeline)
  - [Overview](#overview)
  - [How To Run](#how-to-run)
  - [Flow Diagram](#flow-diagram)
  - [Pipeline Steps](#pipeline-steps)
     - [1. Extract mtDNA with BAMQL](#1-Extract-mtDNA-with-BAMQL)
     - [2. Align mt Reads with MToolBox](#2-Align-mt-Reads-with-MToolBox)
     - [3. Call mtSNV with MitoCaller](#3-Call-mtSNV-with-MitoCaller)
     - [4. Convert MitoCaller output with Mito2VCF](#4-Convert-MitoCaller-output-with-Mito2VCF)
     - [5. Call Heteroplasmy on Paired Samples](#5-Call-Heteroplasmy-on-Paired-Samples)
  - [Inputs](#inputs)
  - [Outputs](#outputs)
     - [1. Extract mtDNA with BAMQL Output](#1-Extract-mtDNA-with-BAMQL-Output)
     - [2. Align mt Reads with MToolBox Output](#2-Align-mt-Reads-with-MToolBox-Output)
     - [3. Call mtSNV with MitoCaller Output](#3-Call-mtSNV-with-MitoCaller-Output)
     - [4. Convert MitoCaller output with Mito2VCF Output](#4-Convert-MitoCaller-output-with-Mito2VCF-Output)
     - [5. Call Heteroplasmy on Paired Samples Output](#5-Call-Heteroplasmy-on-Paired-Samples-Output)
  - [Testing and Validation](#testing-and-validation)
    - [Test Data Set](#test-data-set)
    - [Validation ](#validation-version-number)
    - [Validation Tool](#validation-tool)
  - [References](#references)

## Overview
This nextflow pipeline takes an aligned bam file as input and extracts mitochondrial DNA reads, remaps the reads to a mitochondrial reference genome, and  calls variants. It can use be used in single sample and tumor-normal paired mode. Paired mode gives an addtional heteroplasmy comparison.
___

## How To Run
Samples can be run by specifying a number of paramters:

#### call-mtSNV_input.csv
This input csv requires 3 arguments in single mode, 6 in paired. For reference look at [Inputs](#inputs)
1. normal or tumour
2. sample name
3. bam file path


#### call-mtSNV.config
The config file requires 9 arguments
|| Input Parameter | Required | Type | Description |
|:---|:----------------|:---------|:-----|:------------|
| 1 | `run_name` | yes | string | This is the overall run name, useful in paired sample mode for organizing outputs. The outputs will be housed in a directory with this name + date information automatically pulled from the system. |
| 2 | `sample_mode` | yes | string | 'single' or 'paired'? |
| 3 | `input_csv` | yes | path | Absolute path to tcall-mtSNV_input.csv |
| 4 | `output_dir` | yes | path | Absolute path to location of outputs. |
| 5 | `temp_dir` | yes | path | Absolute path to the directory where the nextflow's intermediate files are saved. If your cluster worker node has the `/scratch` set up, this can be set to it. |
| 6 | `directory_containing_mt_ref_genome_chrRSRS_files` | yes | path | Absolute path to directory containing mitochondrial ref genome and mt ref genome index files. Take a look at the example config for location of a reference if in need of one and copy it. Alternatively, it can be found on cluster directory with reference genomes.  |
| 7 | `gmapdb` | yes | path | Absolute path to to gmapdb directory. Take a look at the example config for location of a reference if in need on and copy it. Alternatively, it can be found on cluster directory with reference genomes.|
| 8 | `save_intermediate_files` | yes | boolean | Save intermediate files. If yes, not only the final BAM, but also the unmerged, unsorted, and duplicates unmarked BAM files will also be saved. |
| 9 | `cache_intermediate_pipeline_steps` | yes | boolean | Enable cahcing to resume pipeline and the end of the last successful process completion when a pipeline fails (if true the default submission script must be modified)
| 10 | `sge_scheduler` | only on sge | boolean | If running on SGE or externally as a collaborator, depending on your permission settings you will need to change "sge_scheduler" to "true" |

___

## Flow Diagram
![flowchart_call-mtSNV](flowchart_call-mtSNV.png)

___
## Pipeline Steps

### 1. Extract mt DNA with BAMQL

Bamql is a package or query language which the Boutros lab published ( https://doi.org/10.1186/s12859-016-1162-y ) a few  years back and is dedicated to extracting reads from BAM files. Why would you use BAMQL vs other methods you might ask? well the main benefit is readability and ease of use. Obviously there are various ways of extracting reads, you can use SamTools in the Perl language or pysam inpython, sambasa,  but these way you go about is not the most straight forward , has low readiability and is very prone to user because: the user must indicate which bit flags they require not using names, but the numeric values of those flags. 

### 2. Align mtDNA with MToolBox
![flowchart_mtoolbox_overview](flowchart_mtoolbox_overview.png)

So once we have mitochondrial reads extracted we proceed to Mtoolbox which can accept as input raw data or prealigned reads. 

In both cases, reads are mapped/remapped by the mapExome.py script which we can choose the mitochondrial reference genome we want to use. either onto the Reconstructed Sapiens Reference Sequence (RSRS) or the revised Cambridge Reference Sequence (rCRS). Our lab uses the rCRS since it is more commonly used. Additional information found here (https://haplogrep.i-med.ac.at/2014/09/08/rcrs-vs-rsrs-vs-hg19/)

Subsequently, reads mapped on mtDNA are realigned onto the nuclear genome (GRCh37/hg19), this is done to discard Nuclear mitochondrial Sequences (NumtS;  and amplification artifacts which might be present. The resulting Sequence Alignment/Map (SAM) file is then processed for ins/dels realignment around a set of known ins/dels, and processed for putative PCR duplicates removal. This step generates a dataset of highly reliable mitochondrial aligned reads.

### 3. Call mtSNV with MitoCaller

Due to the similarities between nuclear and mitochondrial DNA we can use some of the same approaches in variant calling we use for nuclear DNA with a couple modifications which is what mitocaller incorporates.

Variant identification for nuclear DNA, commonly uses a likelihood-based model to combine information from sequence reads and predict the genotype with the highest posterior probability at a site.

But mtDNA analysis is one of a number of instances) in which scoring allelic variation is more complicated, because there are more than the three discrete genotype states found in nuclear DNA. Instead of having two copies of each autosome (chromosomes 1–22), human cells have 100–10,000 separate copies of mtDNA, and different copies of mtDNA may differ in DNA sequence at any base. 

Thus, the conventional nuclear DNA variant caller must be adapted to identify mtDNA variants within this context and modified to allow for allele fractions (i.e., heteroplasmic levels) at a variant site to vary across individuals.

### 4. Convert MitoCaller output with Mito2VCF

mitoCaller2vcf converts results from mitoCaller to vcf format as the output of MitoCaller is a .tsv file.

### 5. Call Heteroplasmy on Paired Samples

Heteroplasmy is the presence of more than one type of organellar genome (mitochondrial DNA or plastid DNA) within a cell or individual. This script compares and contrast heteroplasmy using the normal sample as a reference point.

## Inputs

>The input csv must have all columns below and in the same order. Input are aligned bam files. Sample input file can be found [here](https://github.com/uclahs-cds/pipeline-call-mtSNV/blob/Alfredo-dev/inputs/call-mtSNV_input.csv)

| Field | Type | Description |
|:------|:-----|:------------|
| sample_input_1_type | string | Need to specify "normal" or "tumor". |
| sample_input_1_name | string | Name of sample. This is the name that will be used for file name outputs. |
| sample_input_1_path | path | Absolute path to input bam file. |
| sample_input_2_type | string | Need to specify "normal" or "tumor". |
| sample_input_2_name | string | Name of sample. This is the name that will be used for file name outputs. |
| sample_input_2_path | path | Absolute path to input bam file. |
___

## Outputs

Organized by process 
### 1. Extract mt DNA with BAMQL Output
Outputs Bam file with only mitochondrial reads. Note that these reads are not properly aligned and need to be realigned in the following step.

### 2. Align mtDNA with MToolBox Output
MToolBox has various steps.

*Main outputs:*
*_sorted.bam

*Intermeidate Files Output:*
VCF_dict_tmp
config_extracted_mt_reads_normal_CPCG0196-B1_realigned_recalibrated_merged_bam_reheadered.conf
logassemble.txt
mt_classification_best_results.csv
prioritized_variants.txt
processed_fastq.tar.gz
sample.vcf
summary_*.txt
Directory with mtoolbox intermediate output files

### 3. Call mtSNV with MitoCaller Output
Outputs are a *.tsv file with MitoCaller calls. Note that following Mito2VCF provides a more legible and actionable output which is easier to use.

### 4. Convert MitoCaller output with Mito2VCF Output
Outputs are 2 *.vcf files containing MitoCaller calls.

### 5. Call Heteroplasmy on Paired Samples Output
Outputs are a *.tsv table showing differences in the normal genotype vs tumour genotype. It also gives heteroplasmy_fraction if there is any. 

___

## Testing and Validation

### Test Data Set

Both WGS and WES aligned bam files were used to test in single and tumor-normal paired modes. Input csv with directory paths and used configs included in test_example.csv .

Outputs of such directory in UCLA_CDS/Boutros Lab cluster are:

### Validation Tool

Included is a template for validating your input files. For more information on the tool check out: https://github.com/uclahs-cds/tool-validate-nf

---

## References
01. Masella, A.P., Lalansingh, C.M., Sivasundaram, P. et al. BAMQL: a query language for extracting reads from BAM files. BMC Bioinformatics 17, 305 (2016). [link](https://doi.org/10.1186/s12859-016-1162-y)
02. [BAMQL github](https://github.com/BoutrosLaboratory/bamql/releases/tag/v1.6)
03. Calabrese C, Simone D, Diroma MA, et al. MToolBox: a highly automated pipeline for heteroplasmy annotation and prioritization analysis of human mitochondrial variants in high-throughput sequencing. Bioinformatics. 2014;30(21):3115-3117. [link](https://pubmed.ncbi.nlm.nih.gov/25028726/)
04. [MToolBox github](https://github.com/mitoNGS/MToolBox)
05. [mitoCaller](https://lgsun.irp.nia.nih.gov/hsgu/software/mitoAnalyzer/mitoAnalyzer.htm)
