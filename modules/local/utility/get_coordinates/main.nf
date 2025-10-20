process GET_TRANSCRIPTS_COORDINATES {
    tag "${meta.id}"
    label 'process_low'

    container "community.wave.seqera.io/library/pandas_procs_pyarrow_pip_pruned:a01d9a7721ecb2b7"

    input:
    tuple val(meta), path(transcripts)

    output:
    tuple val(meta), stdout(), emit: transcript_coordinates
    path ("versions.yml"), emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    // Exit if running this module with -profile conda / -profile mamba
    if (workflow.profile.tokenize(',').intersect(['conda', 'mamba']).size() >= 1) {
        error("GET_TRANSCRIPTS_COORDINATES module does not support Conda. Please use Docker / Singularity / Podman instead.")
    }

    prefix = task.ext.prefix ?: "${meta.id}"

    template('get_coordinates.py')

    stub:
    // Exit if running this module with -profile conda / -profile mamba
    if (workflow.profile.tokenize(',').intersect(['conda', 'mamba']).size() >= 1) {
        error("GET_TRANSCRIPTS_COORDINATES module does not support Conda. Please use Docker / Singularity / Podman instead.")
    }
    prefix = task.ext.prefix ?: "${meta.id}"

    """
    echo 

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        GET_TRANSCRIPTS_COORDINATES: "1.0.0"
    END_VERSIONS
    """
}
