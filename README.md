# Boutros Lab call-mtSNV pipeline

### One Sentence Overview
This nextflow pipeline extracts mt reads, remaps the reads to mitochondrial reference genome, and  calls variants using mitoCaller and gives heteroplasmy.


### Index
1. Workflow Flowchart
2. Bamql
3. Mtoolbox
4. Mitocaller
5. CallHeteroplasmy


## 1. Workflow Flowchart
![flowchart_call-mtSNV](flowchart_call-mtSNV.png)

## 2. Bamql
![flowchart_mtoolbox_overview](flowchart_mtoolbox_overview.png)

Bamql is a package or query language which the Boutros lab created a couple of years back and is dedicated to extracting reads from BAM files. Why would you use BAMQL vs other methods you might ask? well the main benefit is readability and ease of use. Obviously there are various ways of extracting reads, you can use SamTools in the Perl language or pysam inpython, sambasa,  but these way you go about is not the most straight forward , has low readiability and is very prone to user because: the user must indicate which bit flags they require not using names, but the numeric values of those flags. 

## 3. Mtoolbox

So once we have mitochondrial reads extracted we proceed to Mtoolbox which can accept as input raw data or prealigned reads. 

In both cases, reads are mapped/remapped by the mapExome.py script which we can choose the mitochondrial reference genome we want to use. either onto the Reconstructed Sapiens Reference Sequence (RSRS) or the revised Cambridge Reference Sequence (rCRS). 

Subsequently, reads mapped on mtDNA are realigned onto the nuclear genome (GRCh37/hg19), this is done to discard Nuclear mitochondrial Sequences (NumtS;  and amplification artifacts which might be present. The resulting Sequence Alignment/Map (SAM) file is then processed for ins/dels realignment around a set of known ins/dels, and processed for putative PCR duplicates removal. This step generates a dataset of highly reliable mitochondrial aligned reads.

## 4. Mitocaller

Mitochondrial DNA is DNA, we can use some of the same approaches in variant calling we use for nuclear DNA with a couple modifications which is what mitocaller incorporates.

Variant identification for nuclear DNA, commonly uses a likelihood-based model to combine information from sequence reads and predict the genotype with the highest posterior probability at a site.

But mtDNA analysis is one of a number of instances) in which scoring allelic variation is more complicated, because there are more than the three discrete genotype states found in nuclear DNA. Instead of having two copies of each autosome (chromosomes 1–22), human cells have 100–10,000 separate copies of mtDNA, and different copies of mtDNA may differ in DNA sequence at any base. 

Thus, the conventional nuclear DNA variant caller must be adapted to identify mtDNA variants within this context and modified to allow for allele fractions (i.e., heteroplasmic levels) at a variant site to vary across individuals.


## 5. CallHeteroplasmy

This is a simple perl script written by Taka to compare and contrast heteroplasmy.
