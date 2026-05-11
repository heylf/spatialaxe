process BAYSOR_RUN {
    tag "${meta.id}"
    label 'process_high'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/ac/ac0d3ff0eccb4d861d4bccff00a0582f610ef2e8e37fc684db6b9436193a0bb6/data' :
        'community.wave.seqera.io/library/baysor_python:3ef186887d7a5e32' }"

    input:
    tuple val(meta), path(transcripts), path(prior_segmentation), path(config), val(scale)

    output:
    tuple val(meta), path("${prefix}/segmentation.csv"), path("${prefix}/segmentation_polygons_2d.json"), emit: segmentation
    tuple val("${task.process}"), val('baysor'), eval("baysor --version 2>&1 | grep -oP '\\d+\\.\\d+\\.\\d+' || echo unknown"), topic: versions, emit: versions_baysor

    when:
    task.ext.when == null || task.ext.when

    script:
    // Exit if running this module with -profile conda / -profile mamba
    if (workflow.profile.tokenize(',').intersect(['conda', 'mamba']).size() >= 1) {
        error("BAYSOR_RUN module does not support Conda. Please use Docker / Singularity / Podman instead.")
    }

    def args = task.ext.args ?: ''
    // Column-based prior (e.g. :cell_id) takes precedence over file-based prior
    def prior_col = task.ext.prior_column ? ":${task.ext.prior_column}" : ''
    def prior_seg = prior_col ?: (prior_segmentation ? prior_segmentation : '')
    def confidence = task.ext.prior_confidence != null ? "--prior-segmentation-confidence=${task.ext.prior_confidence}" : ''
    def scaling_factor = scale ? "--scale=${scale}" : ''
    def config_arg = config ? "--config=${config}" : ''
    prefix = task.ext.prefix ?: "${meta.id}"

    // Build command parts, filtering out empty strings
    def cmd_parts = [
        "baysor run",
        "${transcripts}",
        prior_seg,
        scaling_factor,
        confidence,
        "--output=\"${prefix}/segmentation.csv\"",
        config_arg,
        "--plot",
        "--polygon-format=GeometryCollectionLegacy",
        args
    ].findAll { cmd -> cmd }

    """
    export JULIA_NUM_THREADS=${task.cpus}

    mkdir -p ${prefix}

    ${cmd_parts.join(' \\\n    ')}
    """

    stub:
    // Exit if running this module with -profile conda / -profile mamba
    if (workflow.profile.tokenize(',').intersect(['conda', 'mamba']).size() >= 1) {
        error("BAYSOR_RUN module does not support Conda. Please use Docker / Singularity / Podman instead.")
    }

    prefix = task.ext.prefix ?: "${meta.id}"

    """
    mkdir -p ${prefix}
    touch "${prefix}/segmentation.csv"
    touch "${prefix}/segmentation_polygons_2d.json"
    """
}
