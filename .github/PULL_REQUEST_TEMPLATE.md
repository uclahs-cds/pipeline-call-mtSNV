<!--- Please read each of the following items and confirm by replacing
 !--the [ ] with a [X] --->

- [ ] I have read the [code review guidelines](https://confluence.mednet.ucla.edu/display/BOUTROSLAB/Code+Review+Guidelines) and the [code review best practice on GitHub check-list](https://confluence.mednet.ucla.edu/pages/viewpage.action?pageId=84091668).

- [ ] I have set up the branch protection rule following the [github standards](https://confluence.mednet.ucla.edu/pages/viewpage.action?spaceKey=BOUTROSLAB&title=GitHub+Standards#GitHubStandards-Branchprotectionrule) before opening this pull request, or the branch protection rule has already been set up.

- [ ] I have added my name to the contributors listings in the
``metadata.yaml`` and the ``manifest`` block in the config as part of this pull request, am listed
already, or do not wish to be listed. (*This acknowledgement is optional.*)

- [ ] I have added the changes included in this pull request to the `CHANGELOG.md` under the next release version or unreleased, and updated the date.

- [ ] I have updated the version number in the `metadata.yaml` and config file following [semver](https://semver.org/), or the version number has already been updated. (*Leave it unchecked if you are unsure about new version number and discuss it with the infrastructure team in this PR.*)

- [ ] I have tested the pipeline on at least one A-mini sample with sample_mode set to 'paired' and 'single'. The paths to the test config files and output directories were attached below.

<!--- Briefly describe the changes included in this pull request and the paths to the test cases below
 !--- starting with 'Closes #...' if appropriate --->

Closes #...

**Test Results**

- sample_mode = 'paired'
	- sample_1:    <!-- e.g. A-mini S2.T-1, A-mini S2.T-n1 -->
	- sample_2:    <!-- e.g. A-mini S2.T-1, A-mini S2.T-n1 -->
	- input csv: <!-- path/to/input.csv -->
	- config:    <!-- path/to/xxx.config -->
    - output_folder: <!-- path/to/output_folder -->
- sample_mode = single
	- sample:    <!-- e.g. A-mini S2.T-1, A-mini S2.T-n1 --> 
	- input csv: <!-- path/to/input.csv -->
	- config:    <!-- path/to/xxx.config -->  
    - output_folder: <!-- path/to/output_folder -->
