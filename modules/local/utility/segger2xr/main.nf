process SEGGER2XR {
    tag "$meta.id"
    label 'process_low'

    container "community.wave.seqera.io/library/pip_pandas:5c59aaec7d5d4750"

    input:
    tuple val(meta), path(transcripts)

    output:
    tuple val(meta), path("${prefix}/transcripts.parquet"), emit: transcripts_parquet
    path("versions.yml")                                  , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    // Exit if running this module with -profile conda / -profile mamba
    if (workflow.profile.tokenize(',').intersect(['conda', 'mamba']).size() >= 1) {
        error "SEGGER2XR module does not support Conda. Please use Docker / Singularity / Podman instead."
    }

    template 'segger2xr.py'

    stub:
    // Exit if running this module with -profile conda / -profile mamba
    if (workflow.profile.tokenize(',').intersect(['conda', 'mamba']).size() >= 1) {
        error "SEGGER2XR module does not support Conda. Please use Docker / Singularity / Podman instead."
    }

    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    mkdir -p ${prefix}
    touch "${prefix}/transcripts.parquet"

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        segger2xr: "${task.version}"
    END_VERSIONS
    """
}
