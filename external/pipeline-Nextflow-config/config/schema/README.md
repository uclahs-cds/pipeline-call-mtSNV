# Schema validation

To perform automatic validation of parameters:
- Define a `schema.yaml` detailing the necessary parameters.
    - For a template parameter definition, see [template schema](./schema_template.yaml)
    - For an example, see [example schema](./schema_example.yaml)
- (Optional) Define any necessary custom types and approriate validation functions
    - The custom schema type must define a `custom_schema_types` namespace containing a Map `types` with keys being the type and the values being the function for validating the type.
    - For an example, see [custom types](./custom_schema_types.config)
- In `methods.config`, include the `schema.config` file and call the validation functions:
    - (Optional) If a custom schema is defined, call `schema.load_custom_types("/path/to/custom/schema.config")`
    - Call `schema.validate()`, optionally with an argument pointing to the `schema.yaml` file. By default, `"${projectDir}/config/schema.yaml"` will be used.

## Available types
- `Integer`
- `String`
    - With this type, an additional definition `allow_empty` can be specified to allow an empty string as input. By default, empty strings will not be allowed.
- `Number`
- `List`
- `Bool`
- `Namespace`
    - a Groovy `Map`
- `Path`
    - With this type, an additional definition `mode` must be specified, indicating whether the associated parameter needs to be readable (`mode: 'r'`) or writeable (`mode: 'w'`)

## Available functions
- `validate` - The entrypoint function for validating the parameters
    - Positional args:
        |position|name|type|required|default|description|
        |:--:|:--:|:--:|:--:|:--:|:--:|
        |1|`file_path`|String|No|`"${projectDir}/config/schema.yaml"`|Path to the `schema.yaml` file|
- `load_custom_types` - Function for loading custom types
    - Positional args:
        |position|name|type|required|default|description|
        |:--:|:--:|:--:|:--:|:--:|:--:|
        |1|`custom_types_path`|String|Yes|`null`|Path to config file defining custom types|
- `validate_parameter` - Function for recursively validating a parameter
    - Positional args:
        |position|name|type|required|default|description|
        |:--:|:--:|:--:|:--:|:--:|:--:|
        |1|`options`|Map|Yes|none|Map object where parameter should be defined|
        |2|`name`|String|Yes|none|Name of the parameter|
        |3|`properties`|Map|Yes|none|Map object containing the schema properties for the parameter to validate|
- `check_path` - Function for validating paths and proper permissions
    - Positional args:
        |position|name|type|required|default|description|
        |:--:|:--:|:--:|:--:|:--:|:--:|
        |1|`p`|String|Yes|none|Path to to validate|
        |2|`mode`|String|Yes|none|Permission to check, `w` to check if path is writeable and `r` to check if path is readable|

## Example

To perform validation, load custom types, if any, and call the `validate` function.

Example:
```Nextflow
includeConfig "/path/to/schema.config"
...
methods {
    ...
    setup = {
        ...
        schema.load_custom_types("/path/to/custom.config")
        schema.validate()
    }
}
```
