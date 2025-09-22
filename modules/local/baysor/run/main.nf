process BAYSOR_RUN {
    tag "$meta.id"
    label 'process_high'

    container "khersameesh24/baysor:0.7.1"

    input:
    tuple val(meta), path(transcripts)
    path(prior_segmentation)
    path(config)
    val(scale)

    output:
    tuple val(meta),
          path("${meta.id}/segmentation.csv"),
          path("${meta.id}/segmentation_polygons_2d.json"), emit: segmentation
    path("versions.yml")                                  , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    // Exit if running this module with -profile conda / -profile mamba
    if (workflow.profile.tokenize(',').intersect(['conda', 'mamba']).size() >= 1) {
        error "BAYSOR_RUN module does not support Conda. Please use Docker / Singularity / Podman instead."
    }

    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def prior_seg = "${prior_segmentation}" ? "${prior_segmentation}" : ""
    def scaling_factor = scale ? "--scale=${scale}": ""

    """
    mkdir -p ${prefix}

    baysor run \\
    ${transcripts} \\
    ${prior_seg} \\
    ${scaling_factor} \\
    --output="${prefix}/segmentation.csv" \\
    --config=${config} \\
    --plot \\
    --polygon-format=GeometryCollectionLegacy \\
    ${args}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        baysor: 0.7.1
    END_VERSIONS
    """

    stub:
    // Exit if running this module with -profile conda / -profile mamba
    if (workflow.profile.tokenize(',').intersect(['conda', 'mamba']).size() >= 1) {
        error "BAYSOR_RUN module does not support Conda. Please use Docker / Singularity / Podman instead."
    }

    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    mkdir -p ${prefix}
    touch "${prefix}/segmentation.csv"
    touch "${prefix}/segmentation_polygons_2d.json"

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        baysor: 0.7.1
    END_VERSIONS
    """
}
