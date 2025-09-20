process PARQUET_TO_CSV {
    tag "$meta.id"
    label 'process_low'

    container "community.wave.seqera.io/library/pip_pandas:5c59aaec7d5d4750"

    input:
    tuple val(meta), path(transcripts)
    val(extension)

    output:
    tuple val(meta), path("${meta.id}/*.csv*"), emit: transcripts_csv
    path("versions.yml")                      , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    // Exit if running this module with -profile conda / -profile mamba
    if (workflow.profile.tokenize(',').intersect(['conda', 'mamba']).size() >= 1) {
        error "PARQUET_TO_CSV module does not support Conda. Please use Docker / Singularity / Podman instead."
    }

    template 'parquet_to_csv.py'

    stub:
    // Exit if running this module with -profile conda / -profile mamba
    if (workflow.profile.tokenize(',').intersect(['conda', 'mamba']).size() >= 1) {
        error "PARQUET_TO_CSV module does not support Conda. Please use Docker / Singularity / Podman instead."
    }

    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    mkdir -p ${prefix}
    touch "${prefix}/${transcripts}.csv"

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        spatialconverter: "${task.version}"
    END_VERSIONS
    """
}
