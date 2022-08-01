# Nextflow Configs


- [Overview](#overview)
- [How to use](#how-to-use)
- [Available Configs](#available-configs)
- [License](#License)


## Overview

A set of Nextflow configs commonly used across pipelines.

## How to use

1. Add this repository as a submodule in the pipeline of interest
2. Include the required config files and call necessary functions

## Available Configs

|Module|Description|
|:---|:---|
|[retry.config](./config/retry/retry.config)|Enable Nextflow's process retry mechanism ([How to enable retry](./config/retry/README.md))|
|[schema.config](./config/schema/schema.config)|Automatic parameter validation ([How to perform validation](./config/schema/README.md))|
|[csv_parser.config](./config/csv/csv_parser.config)|CSV parsing ([How to parse a CSV](./config/csv/README.md))|
|[common_methods.config](./config/methods/common_methods.config)|Collection of commonly used config functions ([How to use common functions](./config/methods/README.md))|


## License

Author: Yash Patel (YashPatel@mednet.ucla.edu)

pipeline-Nextflow-config is licensed under the GNU General Public License version 2. See the file LICENSE for the terms of the GNU GPL license.

pipeline-Nextflow-config comprises a set of commonly used Nextflow configs.

Copyright (C) 2022 University of California Los Angeles ("Boutros Lab") All rights reserved.

This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 2 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
