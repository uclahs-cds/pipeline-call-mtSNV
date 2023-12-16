# Changelog
All notable changes to the pipeline-name pipeline.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

This project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---
## [Unreleased]
### Changed
- Change input format to YAML.
- Auto-detect sample mode.
### Added
### Fixed

---
## [3.0.1] - 2023-12-07
### Changed
- Parameterize Docker registry
- Use `ghcr.io/uclahs-cds` as default registry

## [3.0.0] - 2022-09-08
### Added
- Add F16 config file
- Use external resource allocation module

### Changed
- Standardize config file structure
- Standardize filename

---
## [3.0.0-rc.1] - 2022-07-08
### Added
- Add F32 config file

### Changed
- Standardize log and output directories
- Reorganize repo to remove process directory and singular directory names

### Fixed
- #73 | Increase memory allocation to mitoCaller2vcf module

---
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
- #61 + #62  | Fix normal tumor genotype flip on final call-heteroplasmy comparison and fix observed file overwrite

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
