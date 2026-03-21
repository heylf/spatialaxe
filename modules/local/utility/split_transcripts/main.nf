process SPLIT_TRANSCRIPTS {
    tag "$meta.id"
    label 'process_low'

    container "community.wave.seqera.io/library/pip_pandas:5c59aaec7d5d4750"

    input:
    tuple val(meta), path(transcripts)
    val(x_bins)
    val(y_bins)

    output:
    tuple val(meta), path("${meta.id}/splits.csv"), emit: splits_csv
    tuple val("${task.process}"), val('python'), eval('python3 --version | awk \\'\\'{print \\$2}\\'\\'''), topic: versions, emit: versions_python

    when:
    task.ext.when == null || task.ext.when

    script:
    // Exit if running this module with -profile conda / -profile mamba
    if (workflow.profile.tokenize(',').intersect(['conda', 'mamba']).size() >= 1) {
        error "SPLIT_TRANSCRIPTS module does not support Conda. Please use Docker / Singularity / Podman instead."
    }
    def prefix = task.ext.prefix ?: "${meta.id}"

    template 'split_transcripts.py'

    stub:
    // Exit if running this module with -profile conda / -profile mamba
    if (workflow.profile.tokenize(',').intersect(['conda', 'mamba']).size() >= 1) {
        error "SPLIT_TRANSCRIPTS module does not support Conda. Please use Docker / Singularity / Podman instead."
    }
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    mkdir -p ${prefix}
    touch "${prefix}/${transcripts}.parquet"
    """
}
