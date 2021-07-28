# Changelog
All notable changes to the pipeline-name pipeline.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

This project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---
## [1.0.0-RC1] - 2021-07-28
### Added
- #56 | ce1e16d: Added PULL_REQUEST_TEMPLATE.md


## [1.0.0-RC1] - 2021-07-27
### Changed
- #54: README.md cleaned up for typos and incorrect statements
- #54: Main output of align_mtDNA-MToolBox changed to include summary_date.txt and mt_classification_best_results.csv


## [1.0.0-RC1] - 2021-07-15
### Added
- sha512 validation to docker images
- Additional resource allocation files and labels
- table with output detail in README.md

### Changed
- reource allocation settings
- output file grouping in align_mtDNA: "*.{txt,conf,csv,vcf,gz}"

## [Unreleased] - 2021-06-28
### Added
- #51 Documentation to CHANGELOG.md

### Changed
- name of call-mtSNV.config to nextflow.config


## [Unreleased] - 2021-06-28
### Added
- CHANGELOG.md

### Changed
- Updates and reformatting to README.md 
- Moved resource allocation from nextflow scripts to configuration file midmem.config
- Modified inputs:
    - Before: Needed to specify both mt reference genome and directory with index files needed
    - Now: Just need to specify single directory containing everything
- Added missing intermediate files for output from align_mtDNA_MToolBox.nf


## [Unreleased] - 2021-06-10
### Added
- #44 | d9bb7c2: Checksum update
- Issue reporting template 

### Fixed
- Error in call_heteroplasmy.nf resulting in no output due to improper file paths


## [Unreleased] - 2021-05-14
### Added
- #31 CI/CD base

### Changed
- Directory output organization

### Fixed
- Extensive code cleanup based on CI/CD