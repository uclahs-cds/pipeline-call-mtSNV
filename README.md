# Boutros Lab call-mtSNV pipeline

- [Boutros Lab call-mtSNV pipeline](#boutros-lab-call-mtsnv-pipeline)
  - [Overview](#overview)
  - [How To Run](#how-to-run)
  - [Flow Diagram](#flow-diagram)
  - [Pipeline Steps](#pipeline-steps)
    - [1. Extract mtDNA with BAMQL](#1-extract-mtdna-with-bamql)
    - [2. Align mtDNA with MToolBox](#2-align-mtdna-with-mtoolbox)
    - [3. Call mtSNV with mitoCaller](#3-call-mtsnv-with-mitocaller)
    - [4. Convert mitoCaller output with Mito2VCF](#4-convert-mitocaller-output-with-mito2vcf)
    - [5. Call Heteroplasmy on Paired Samples](#5-call-heteroplasmy-on-paired-samples)
  - [Inputs](#inputs)
    - [input.yaml](#inputyaml)
      - [Single Mode](#single-mode)
      - [Paired Mode](#paired-mode)
    - [input.config](#inputconfig)
  - [Outputs](#outputs)
  - [Testing and Validation](#testing-and-validation)
    - [Test Data Set](#test-data-set)
    - [Validation Tool](#validation-tool)
  - [References](#references)
  - [Discussions](#discussions)
  - [Contributors](#contributors)
  - [Please see list of Contributors at GitHub.](#please-see-list-of-contributors-at-github)
  - [License](#license)

## Overview
This Nextflow pipeline takes as input either a single aligned BAM or paired normal-tumor BAMs and extracts mitochondrial DNA reads, remaps the reads to a mitochondrial reference genome, and subsequently calls variants. Paired mode gives an additional heteroplasmy comparison.
___

## How To Run
> **Note**: Because this pipeline uses an image stored in the GitHub Container Registry, you must follow the steps listed in the [Docker Introduction](https://uclahs-cds.atlassian.net/wiki/spaces/BOUTROSLAB/pages/3190419/Docker+Introduction#DockerIntroduction-HowtosetupPATandlogintotheregistryHowtosetupPATandlogintotheregistry) on Confluence to set up a PAT for your GitHub account and log into the registry on the cluster before running this pipeline.

Samples can be run by specifying file locations in the [`input.yaml`](./input/template.yaml) and setting pipeline-specific parameters in the [`input.config`](./config/template.config).
___

## Flow Diagram
![flowchart_call-mtSNV](flowchart_call-mtSNV.png)
___
## Pipeline Steps

### 1. Extract mtDNA with BAMQL

[BAMQL](https://doi.org/10.1186/s12859-016-1162-y) is a package or query language published by the Boutros lab for extracting reads from BAM files.<sup>1-2</sup>

### 2. Align mtDNA with MToolBox
![flowchart_mtoolbox_overview](flowchart_mtoolbox_overview.png)

MToolBox is used to align the extracted mitochondrial reads. It can accept as input either raw data or prealigned reads.<sup>3</sup> In both cases, reads are mapped by the mapExome.py script to a mitochondrial reference genome. The current pipeline uses the Reconstructed Sapiens Reference Sequence(RSRS).<sup>4</sup> This generates a dataset of reliable mitochondrial aligned reads.

### 3. Call mtSNV with mitoCaller

While human diploid cells have two copies of each chromosome, human cells can have a varying quantity of mtDNA ranging from 100-10,000 copies.  The resultant high coverage in bulk sequencing data allows for the sensitive detection of low frequency variation seen with mitoCaller. [mitoCaller](https://doi.org/10.1371/journal.pgen.1005306) is a script which uses a mitochondrial specific algorithm designed to account for these unique factors to identify mtDNA variants.<sup>5-6</sup>

### 4. Convert mitoCaller output with Mito2VCF

mitoCaller2VCF converts results from mitoCaller to VCF format as the output of mitoCaller is a TSV file and must be processed to increase legibility.<sup>5</sup>

### 5. Call Heteroplasmy on Paired Samples

Heteroplasmy is the presence of more than one type of organellar genome (mitochondrial DNA or plastid DNA) within a cell or individual. This script compares heteroplasmy using the normal sample as a reference point.

## Inputs

### input.yaml
This input YAML must comply with the format in the provided [template](./input/template.yaml).

| Field | Type | Description |
|:------|:-----|:----------------------------|
| project_id | string | Name of project. |
| sample_id | string | Name of sample. |
| normal_id | string | Identifier for normal samples. |
| normal_BAM | path | Absolute path to normal BAM file. |
| tumor_id | string | Identifier for tumor samples. |
| tumor_BAM | path | Absolute path to tumor BAM file. |

#### Single Mode

Provide either a normal sample or tumor sample and leave the other entry blank in the YAML. The data will be organized by the provided sample's ID.

#### Paired Mode

The data will be organized under the tumor sample ID.

### input.config
The config file can take 6 arguments. See provided [template](./config/template.config).
|| Input Parameter | Required | Type | Description |
|:---|:----------------|:---------|:-----|:----------------------------|
| 1 | `dataset_id` | yes | string | dataset identifier attached to pipeline output. |
| 2 | `output_dir` | yes | path | Absolute path to location of output. |
| 3 | `mt_ref_genome_dir` | yes | path | Absolute path to directory containing mitochondrial ref genome and mt ref genome index files. Path: `/hot/ref/mitochondria_ref/genome_fasta`|
| 4 | `gmapdb` | yes | path | Absolute path to to gmapdb directory. Path: `/hot/ref/mitochondria_ref/gmapdb/gmapdb_2021-03-08` |
| 5 | `save_intermediate_files` | no | boolean | Save intermediate files. If yes, not only the final BAM, but also the unmerged, unsorted, and duplicates unmarked BAM files will also be saved. Default is set to `false`. |
| 6 | `cache_intermediate_pipeline_steps` | no | boolean | Enable caching to resume pipeline and the end of the last successful process completion when a pipeline fails (if true the default submission script must be modified). Default is set to `false`.

## Outputs

|Process| Output | category| Description |
|:------|:--------|:--------|:----------------|
|extract_mtDNA_BAMQL|*OUT2-sorted.bam|main|Outputs BAM file with only mitochondrial reads|
|align_mtDNA_MToolBox|.bam|main|Aligned, sorted, mitochondrial reads in BAM format|
|align_mtDNA_MToolBox|prioritized_variants.txt|main|Contains annotation only for prioritized variants for each sample analyzed,sorted by increasing nucleotide variability|
|align_mtDNA_MToolBox|summary*.txt|main|Summary of selected options. Includes predicted haplogroups, total and prioritized variants, coverage of reconstructed genomes, count of homoplasmic and heteroplasmic variants|
|align_mtDNA_MToolBox|.vcf|intermediate|Contains mitochondrial variant positions against reference genome|
|align_mtDNA_MToolBox|.csv|intermediate|Contains the best haplogroup prediction for each sequence|
|align_mtDNA_MToolBox|folder OUT_*|intermediate|This folder contains additional intermediate files. Description of the contents can be found [here](https://github.com/mitoNGS/MToolBox/wiki/Output-files)|
|call_mtSNV_mitoCaller|*mitoCaller.tsv|main|Contains mtDNA variants (i.e., homoplasmies and heteroplasmies)|
|call_mtSNV_mitoCaller|*mitoCaller.tsv|intermediate|gzipped tsv file|
|convert_mitoCaller2VCF|*.vcf|main|2 *.VCF files containing mitoCaller calls in more legible format|
|call_heteroplasmy|*.tsv|main|a *.tsv table showing differences in the normal genotype vs tumor genotype. It also gives heteroplasmy_fraction if there is any.|

___

## Testing and Validation

### Test Data Set

Both WGS and WES aligned BAM files were used to test in single and tumor-normal paired modes.

|| Type | Mode | Size | CPU threads |PeakVMemory | Run Time |
|:--|:---|:----|:-----|:-----|:------|:------|
|1|WES|Single|4GB|72 | 9.381 GB | ~4 min|
|2|WES|Paired|4GB/4GB|72 | 12.317 GB |~8 min |
|3|WGS|Single|399GB|72 | 21.042 GB | ~2h 40 min|
|4|WGS|Paired|399GB/740GB|72 | 26.615 GB | ~5 hours|

### Validation Tool

Included is a template for validating your input files. For more information on the tool check out: https://github.com/uclahs-cds/tool-validate-nf

---

## References
01. [Masella, A.P., Lalansingh, C.M., Sivasundaram, P. et al. BAMQL: a query language for extracting reads from BAM files. BMC Bioinformatics 17, 305 (2016)](https://doi.org/10.1186/s12859-016-1162-y)
02. [BAMQL github](https://github.com/BoutrosLaboratory/bamql/releases/tag/v1.6)
03. [Calabrese C, Simone D, Diroma MA, et al. MToolBox: a highly automated pipeline for heteroplasmy annotation and prioritization analysis of human mitochondrial variants in high-throughput sequencing. Bioinformatics. 2014;30(21):3115-3117](https://pubmed.ncbi.nlm.nih.gov/25028726/)
04. [MToolBox github](https://github.com/mitoNGS/MToolBox)
05. [mitoCaller](https://lgsun.irp.nia.nih.gov/hsgu/software/mitoAnalyzer/mitoAnalyzer.htm)
06. [Ding J, Sidore C, Butler TJ, Wing MK, Qian Y, et al. (2015) Correction: Assessing Mitochondrial DNA Variation and Copy Number in Lymphocytes of ~2,000 Sardinians Using Tailored Sequencing Analysis Tools](https://doi.org/10.1371/journal.pgen.1005306)

---

## Discussions
- [Issue tracker](https://github.com/uclahs-cds/pipeline-call-mtSNV/issues) to report errors and enhancement ideas.
- Discussions can take place in [<pipeline> Discussions](https://github.com/uclahs-cds/pipeline-call-mtSNV/discussions)
- [<pipeline> pull requests](https://github.com/uclahs-cds/pipeline-call-mtSNV/pulls) are also open for discussion

---

## Contributors
Please see list of [Contributors](https://github.com/uclahs-cds/pipeline-call-mtSNV/graphs/contributors) at GitHub.
---

## License

Author: Alfredo Gonzalez (alfgonzalez@mednet.ucla.edu), Takafumi Yamaguchi (tyamaguchi@mednet.ucla.edu), Jieun Oh (jieunoh@mednet.ucla.edu), Kiarod Pashminehazar (kpashminehazar@mednet.ucla.edu)

Call-mtSNV is licensed under the GNU General Public License version 2. See the file LICENSE for the terms of the GNU GPL license.

Call-mtSNV takes a single aligned BAM or pair of normal tumor BAMs and does variant calling for mtDNA.

Copyright (C) 2021-2024 University of California Los Angeles ("Boutros Lab") All rights reserved.

This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 2 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
