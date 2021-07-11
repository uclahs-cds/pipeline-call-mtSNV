# Changelog
All notable changes to the pipeline-name pipeline.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

This project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Pre-release] - 2021-06-28
### Added
- CHANGELOG.md

### Changed
- Updates and reformatting to README.md 
- Moved resource allocation from nextflow scripts to configuration file midmem.config
- Modified inputs:
    - Before: Needed to specify both mt reference genome and directory with index files needed
    - Now: Just need to specify single directory containing everything
- Added missing intermediate files for output from align_mtDNA_MToolBox.nf

## [Pre-release] - 2021-06-10
### Added
- #44 | d9bb7c2: Checksum update
- Issue reporting template 

### Fixed
- Error in call_heteroplasmy.nf resulting in no output due to improper file paths


## [Pre-release] - 2021-05-14
### Added
- #31 CI/CD base

### Changed
- Directory output organization

### Fixed
- Extensive code cleanup based on CI/CD