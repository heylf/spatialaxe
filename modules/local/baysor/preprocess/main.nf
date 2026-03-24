process BAYSOR_PREPROCESS_TRANSCRIPTS {
    tag "${meta.id}"
    label 'process_medium'

    container "community.wave.seqera.io/library/pandas_procs_pyarrow_pip_pruned:a01d9a7721ecb2b7"

    input:
    tuple val(meta), path(transcripts)
    val min_qv
    val max_x
    val min_x
    val max_y
    val min_y

    output:
    tuple val(meta), path("${prefix}/filtered_transcripts.csv"), emit: transcripts_file
    tuple val("${task.process}"), val('python'), eval("python3 --version | sed 's/Python //'"), topic: versions, emit: versions_python

    when:
    task.ext.when == null || task.ext.when

    script:
    // Exit if running this module with -profile conda / -profile mamba
    if (workflow.profile.tokenize(',').intersect(['conda', 'mamba']).size() >= 1) {
        error("BAYSOR_PREPROCESS_TRANSCRIPTS module does not support Conda. Please use Docker / Singularity / Podman instead.")
    }

    prefix = task.ext.prefix ?: "${meta.id}"

    """
    preprocess_transcripts.py \\
        --transcripts ${transcripts} \\
        --prefix ${prefix} \\
        --min-qv ${min_qv} \\
        --min-x ${min_x} \\
        --max-x ${max_x} \\
        --min-y ${min_y} \\
        --max-y ${max_y}
    """

    stub:
    // Exit if running this module with -profile conda / -profile mamba
    if (workflow.profile.tokenize(',').intersect(['conda', 'mamba']).size() >= 1) {
        error("BAYSOR_PREPROCESS_TRANSCRIPTS module does not support Conda. Please use Docker / Singularity / Podman instead.")
    }

    prefix = task.ext.prefix ?: "${meta.id}"

    """
    mkdir -p ${prefix}
    touch ${prefix}/filtered_transcripts.csv
    """
}
