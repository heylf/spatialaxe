process BAYSOR_PREPROCESS_TRANSCRIPTS {
    tag "$meta.id"
    label 'process_low'

    container "ghcr.io/scverse/spatialdata:spatialdata0.3.0_spatialdata-io0.1.7_spatialdata-plot0.2.9"

    input:
    tuple val(meta), path(transcripts)
    val(min_qv)
    val(max_x)
    val(min_x)
    val(max_y)
    val(min_y)

    output:
    tuple val(meta),
          path("${meta.id}/filtered_transcripts.parquet"), emit: transcripts_parquet
    path("versions.yml")                                 , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    // Exit if running this module with -profile conda / -profile mamba
    if (workflow.profile.tokenize(',').intersect(['conda', 'mamba']).size() >= 1) {
        error "BAYSOR_PREPROCESS_TRANSCRIPTS module does not support Conda. Please use Docker / Singularity / Podman instead."
    }

    def prefix = task.ext.prefix ?: "${meta.id}"

    template 'preprocess_transcripts.py'

    stub:
    // Exit if running this module with -profile conda / -profile mamba
    if (workflow.profile.tokenize(',').intersect(['conda', 'mamba']).size() >= 1) {
        error "BAYSOR_PREPROCESS_TRANSCRIPTS module does not support Conda. Please use Docker / Singularity / Podman instead."
    }

    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    mkdir -p ${prefix}
    touch ${prefix}/filtered_transcripts.parquet

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        baysor_preprocess_transcripts: "1.0.0"
    END_VERSIONS
    """
}
