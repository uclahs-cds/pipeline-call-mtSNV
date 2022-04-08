# Changelog
All notable changes to the pipeline-name pipeline.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

This project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---
## [Unreleased]
### Fixed
- #61 + #62  | normal tumour genotyped flipping on final call-heteroplasmy comparison and overwritting

### Changed
- Input format and workflow logic
- Updated call-heteroplasmy docker image version from 1.0.0 -> 1.0.1
- Output name to be more conventional
- Update .gitignore
- GPL2 License added

---
## [1.0.0] - 2021-08-20
### Added
- Initial release

---
## [1.0.0-rc1] - 2021-08-10
### Added
- #56 | ce1e16d: Added PULL_REQUEST_TEMPLATE.md

### Changed
- #53: Update resource allocation to newest standard
- #39: output file grouping in align_mtDNA: "*.{txt,conf,csv,vcf,gz}"
