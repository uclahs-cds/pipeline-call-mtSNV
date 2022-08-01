# Methods

To use a common `methods` function:
- In the pipeline-specific `methods.config`, include the `common_methods.config` file **before** the `methods` namespace
- Use any of the available functions as needed

> **WARNING**: If the pipeline-specific `methods` namespace contains a function of the same name as one found in `common_methods.config`, one will override the other based on order of inclusion:
> - If `common_methods.config` is included *before* the pipeline-specific `methods` namespace, the pipeline-specific function will override the common function
> - If `common_methods.config` is included *after* the pipeline-specific `methods` namespace, the common function will override the pipeline-specific function

## Available functions
- `set_resources_allocation` - Function to load base allocations, detect node type, and node-specific allocations; generally should be called in the pipeline's `methods.set_up()` function

## Example

```Nextflow
includeConfig "/path/to/common_methods.config"
...
methods {
    ...
    set_up = {
        ...
        methods.set_resources_allocation()
    }
}
```