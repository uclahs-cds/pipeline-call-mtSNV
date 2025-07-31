# Changelog

All notable changes to the pipeline-name pipeline.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

This project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [unreleased]

### Added
- tumor purity option for `call_heteroplasmy` process
- Add option to start running from call_mtSNV and skip extract_mtDNA and align_mtDNA
---
## [6.0.0-rc.1] - 2025-03-03

### Added

- Add downsample BAM functionality
- Generate sha512 Checksums for `*.bam` and `*.vcf.gz` files
- Create index files for output `*.bam` and output `*.vcf.gz` files
- Add NFtest asserts for index files
- Add NFTest case coverage for the downsample BAM process
- Generate sha512 checksum for heteroplasmy `*.tsv`

### Changed

- Update SAMTools version to 1.21
- Reclassify MToolBox output prioritized_variants as a primary output
- Reorganize processes into subworkflows
- Change NFTest to accommodate for the change from `*.vcf` to `*.vcf.gz`
- Include `*.bam` and `*.bai` files for output validation
- Move validation processes into workflows
- Filename standard from `processName/` to `workflowName/processName`
- Change process level `containerOptions` to be sourced from `ext` namespace
- Update `README.md` outputs section to match pipeline

### Fixed

- Add ability to modulate validation stringency level for downsample BAM process

## [5.1.0] - 2024-07-30

### Added

- Add support for abbreviated index file extensions `*.bai` and `*.crai`

### Changed

- Move index file discovery to methods.config

## [5.0.0] - 2024-07-23

### Added

- Add `CRAM` input support.
- Add CRAM cases to NFTest.
- Add additional regression tests for all nodes and input types.
- Output pipeline parameters to log directory using `store_object_as_json`

### Changed

- Change NFTest to use Illumina samples.
- Update Nextflow configuration test workflows.
- Change input template to require sample ID's with data.
- Update process log capturing mechanism to utilize `methods.setup_process_afterscript()`.

### Fixed

- Fix NFTest global.config.
- Fix NFTest assert scripts to remove linter errors.

## [4.0.0] - 2024-03-22

### Changed

- Update `nextflow.config` version number.

## [4.0.0-rc.1] - 2024-03-06

### Added

- Add NFTest compatibility
- Add parameter validation
- Add index files for sample BAMs to `extract_mtDNA_BAMQL` leading to significant runtime reduction.
- Add base resource modification functionality.
- Add `methods.setup_docker_cpus()` to `methods.config` setup.
- Add workflow to build and push documentation to GitHub Pages
- Add workflow to run Nextflow configuration regression tests
- Add one regression test

### Changed

- Change input format to YAML.
- Auto-detect sample mode.
- Update `output_dir` parameter to support CLI argument input.
- Update `methods.config` to use external `set_env` function via `common_methods.config`.
- Update sample ID handling to extract from supplied BAM files.
- Add resource retry mechanism for module processes.
- Update input and output validation to use external PipeVal module.
- Change `methods.check_max` to modularized `methods.check_limits`.

## [3.0.2] - 2023-12-22

### Changed

- Update `nextflow.config` version number to correct previous release

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

## [3.0.0-rc.1] - 2022-07-08

### Added

- Add F32 config file

### Changed

- Standardize log and output directories
- Reorganize repo to remove process directory and singular directory names

### Fixed

- #73 | Increase memory allocation to mitoCaller2vcf module

## [2.0.0] - 2022-04-12

### Added

- Add GPL2 License

### Changed

- Change input format
- Change `main.nf` workflow logic
- Update call-heteroplasmy docker image version from 1.0.0 -> 1.0.1
- Modify output name to be more conventional
- Update .gitignore

### Fixed

- #61 + #62 | Fix normal tumor genotype flip on final call-heteroplasmy comparison and fix observed file overwrite

## [1.0.0] - 2021-08-20

### Added

- Initial release

## [1.0.0-rc1] - 2021-08-10

### Added

- #56 | ce1e16d: Add PULL_REQUEST_TEMPLATE.md

### Changed

- #53: Update resource allocation to newest standard
- #39: Group output files in align_mtDNA: "\*.{txt,conf,csv,vcf,gz}"

[1.0.0]: https://github.com/uclahs-cds/pipeline-call-mtSNV/compare/v1.0.0-rc1...v1.0.0
[1.0.0-rc1]: https://github.com/uclahs-cds/pipeline-call-mtSNV/releases/tag/v1.0.0-rc1
[2.0.0]: https://github.com/uclahs-cds/pipeline-call-mtSNV/compare/v1.0.0...v2.0.0
[3.0.0]: https://github.com/uclahs-cds/pipeline-call-mtSNV/compare/v3.0.0-rc.1...v3.0.0
[3.0.0-rc.1]: https://github.com/uclahs-cds/pipeline-call-mtSNV/compare/v2.0.0...v3.0.0-rc.1
[3.0.1]: https://github.com/uclahs-cds/pipeline-call-mtSNV/compare/v3.0.0...v3.0.1
[3.0.2]: https://github.com/uclahs-cds/pipeline-call-mtSNV/compare/v3.0.1...v3.0.2
[4.0.0-rc.1]: https://github.com/uclahs-cds/pipeline-call-mtSNV/compare/v3.0.2...v4.0.0-rc.1
[4.0.0]: https://github.com/uclahs-cds/pipeline-call-mtSNV/compare/v4.0.0-rc.1...v4.0.0
[5.0.0]: https://github.com/uclahs-cds/pipeline-call-mtSNV/compare/v4.0.0...v5.0.0
[5.1.0]: https://github.com/uclahs-cds/pipeline-call-mtSNV/compare/v5.0.0...v5.1.0
[6.0.0-rc.1]: https://github.com/uclahs-cds/pipeline-call-mtSNV/compare/v5.1.0...v6.0.0-rc.1
