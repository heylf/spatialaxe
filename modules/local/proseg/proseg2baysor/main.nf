process PROSEG2BAYSOR {
    tag "$meta.id"
    label 'process_high'

    container "khersameesh24/proseg:2.0.0"

    input:
    tuple val(meta), path(cell_polygons), path(transcript_metadata)

    output:
    tuple val(meta), path("${meta}/cell-polygons.geojson")  , emit: xr_polygons
    tuple val(meta), path("${meta}/transcript-metadata.csv"), emit: xr_metadata
    path("versions.yml")                                    , emit: versions

    script:
    // Exit if running this module with -profile conda / -profile mamba
    if (workflow.profile.tokenize(',').intersect(['conda', 'mamba']).size() >= 1) {
        error "PROSEG2BAYSOR module does not support Conda. Please use Docker / Singularity / Podman instead."
    }

    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    proseg-to-baysor  \\
        ${transcript_metadata} \\
        ${cell_polygons} \\
        --output-transcript-metadata ${prefix}/transcript-metadata.csv \\
        --output-cell-polygons ${prefix}/cell-polygons.geojson \\
        ${args}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        proseg: \$(proseg --version | sed 's/proseg //')
    END_VERSIONS

    """

    stub:
    // Exit if running this module with -profile conda / -profile mamba
    if (workflow.profile.tokenize(',').intersect(['conda', 'mamba']).size() >= 1) {
        error "PROSEG module does not support Conda. Please use Docker / Singularity / Podman instead."
    }

    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    mkdir -p ${prefix}
    touch "${prefix}/transcript-metadata.csv"
    touch "${prefix}/cell-polygons.geojson"

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        proseg: \$(proseg --version | sed 's/proseg //')
    END_VERSIONS
    """
}
