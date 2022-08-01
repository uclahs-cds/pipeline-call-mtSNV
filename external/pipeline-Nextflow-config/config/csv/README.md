# CSV Parser

To parse a CSV file with a header line:
- Define a list of fields required from the header
- In `methods.config`, include the `csv_parser.config` file and call `csv_parser.parse_csv(</path/to/csv>, <fields>)`

The function returns a `List` of `Maps`, where each `Map` corresponds to the values extracted for the requested fields for a single line in the CSV.

## Available functions
- `parse_csv` - Function for parsing a CSV file
    - Positional args:
        |position|name|type|required|default|description|
        |:--:|:--:|:--:|:--:|:--:|:--:|
        |1|`csv_file`|String|Yes|none|String representing path to CSV file for parsing|
        |2|`fields`|List|Yes|none|List of fields to parse from CSV file|

## Example

To load a a CSV file defined at `params.input_csv = /hot/path/to/my.csv`, containing the columns `patient, sample, path`:
```Nextflow
includeConfig "/path/to/csv_parser.config"
...
methods {
    ...
    def fields = ['patient', 'sample', 'path']
    parsed_inputs = csv_parser.parse_csv(params.input_csv, fields)
}
```
