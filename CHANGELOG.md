# Changelog
All notable changes to the pipeline-name pipeline.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

This project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---
## [Unreleased]
### Changed
- Standardize log and output directories
- Add F32 config file
- Reorganize repo to remove process directory and singular directory names

## [2.0.0] - 2022-04-12
### Added
- Add GPL2 License

### Changed
- Change input format
- Change main.nf workflow logic
- Update call-heteroplasmy docker image version from 1.0.0 -> 1.0.1
- Modify output name to be more conventional
- Update .gitignore

### Fixed
- #61 + #62  | Fix normal tumour genotype flip on final call-heteroplasmy comparison and fix observed file overwrite

---
## [1.0.0] - 2021-08-20
### Added
- Initial release

---
## [1.0.0-rc1] - 2021-08-10
### Added
- #56 | ce1e16d: Add PULL_REQUEST_TEMPLATE.md

### Changed
- #53: Update resource allocation to newest standard
- #39: Group output files in align_mtDNA: "*.{txt,conf,csv,vcf,gz}"
