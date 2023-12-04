process Validate_Inputs {
    container params.validate_docker_image
    label 'process_low'

    input:
        tuple(
            val(type),
            val(name),
            path(file)
            )

    script:
        """
        set -euo pipefail
        python -m validate -t file-input ${file}
        """
    }

process validate_outputs {
    container  params.validate_docker_image

    input:
        path(file)

    script:
        """
        set -euo pipefail
        python3 -m validate -t sha512-gen ${file}
        """
    }

