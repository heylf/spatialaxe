process RESOLIFT {
    tag "${meta.id}"
    label 'process_low'

    container "khersameesh24/resolift:1.0.0"

    input:
    tuple val(meta), path(morphology_tiff)

    output:
    tuple val(meta), path("${prefix}/morphology.ome.enhanced.tiff"), emit: enhanced_tiff
    path ("versions.yml"), emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    // Exit if running this module with -profile conda / -profile mamba
    if (workflow.profile.tokenize(',').intersect(['conda', 'mamba']).size() >= 1) {
        error("RESOLIFT module does not support Conda. Please use Docker / Singularity / Podman instead.")
    }

    def args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${meta.id}"

    """
    mkdir -p ${prefix}

    resolift \\
        -i ${morphology_tiff} \\
        -o ${prefix}/morphology.ome.enhanced.tiff \\
        ${args}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        resolift: v1.0.0
    END_VERSIONS
    """

    stub:
    // Exit if running this module with -profile conda / -profile mamba
    if (workflow.profile.tokenize(',').intersect(['conda', 'mamba']).size() >= 1) {
        error("RESOLIFT module does not support Conda. Please use Docker / Singularity / Podman instead.")
    }
    prefix = task.ext.prefix ?: "${meta.id}"

    """
    mkdir -p ${prefix}
    touch "${prefix}/morphology.ome.enhanced.tiff"

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        resolift: v1.0.0
    END_VERSIONS
    """
}
