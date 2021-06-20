# Boutros Lab call-mtSNV pipeline

-[Boutros Lab call-mtSNV pipeline](#Boutros-Lab-call-mtSNV-pipeline)
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
  - [Testing and Validation](#testing-and-validation)
    - [Test Data Set](#test-data-set)
    - [Validation ](#validation-version-number)
    - [Validation Tool](#validation-tool)
  - [References](#references)

## Overview
This nextflow pipeline extracts mt reads, remaps the reads to mitochondrial reference genome, and  calls variants using mitoCaller and gives heteroplasmy.
___

## How To Run

___

## Flow Diagram
![flowchart_call-mtSNV](flowchart_call-mtSNV.png)

___
## Pipeline Steps

### 1. Extract mt DNA with BAMQL
![flowchart_mtoolbox_overview](flowchart_mtoolbox_overview.png)

Bamql is a package or query language which the Boutros lab published ( https://doi.org/10.1186/s12859-016-1162-y ) a few  years back and is dedicated to extracting reads from BAM files. Why would you use BAMQL vs other methods you might ask? well the main benefit is readability and ease of use. Obviously there are various ways of extracting reads, you can use SamTools in the Perl language or pysam inpython, sambasa,  but these way you go about is not the most straight forward , has low readiability and is very prone to user because: the user must indicate which bit flags they require not using names, but the numeric values of those flags. 

### 2. Align mtDNA with MToolBox

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

___

## Outputs

___

## Testing and Validation

### Test Data Set

A 2-3 sentence description of the test data set(s) used to validate and test this pipeline. If possible, include references and links for how to access and use the test dataset

### Validation <version number\>


### Validation Tool

Included is a template for validating your input files. For more information on the tool check out: https://github.com/uclahs-cds/tool-validate-nf

---

## References