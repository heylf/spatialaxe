process GET_TRANSCRIPTS_COORDINATES {
    tag "${meta.id}"
    label 'process_low'

    container "community.wave.seqera.io/library/pandas_procs_pyarrow_pip_pruned:a01d9a7721ecb2b7"

    input:
    tuple val(meta), path(transcripts)

    output:
    stdout()
    tuple val("${task.process}"), val('python'), eval('python3 --version | awk \\'\\'{print \\$2}\\'\\'''), topic: versions, emit: versions_python

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
    """
}
