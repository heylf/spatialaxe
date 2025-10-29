process PARQUET_TO_CSV {
    tag "$meta.id"
    label 'process_low'

    container "community.wave.seqera.io/library/pandas_procs_pyarrow_pip_pruned:a01d9a7721ecb2b7"

    input:
    tuple val(meta), path(transcripts)
    val(extension)

    output:
    tuple val(meta), path("${prefix}/*.csv*"), emit: transcripts_csv
    path("versions.yml")                     , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    // Exit if running this module with -profile conda / -profile mamba
    if (workflow.profile.tokenize(',').intersect(['conda', 'mamba']).size() >= 1) {
        error "PARQUET_TO_CSV module does not support Conda. Please use Docker / Singularity / Podman instead."
    }
    prefix = task.ext.prefix ?: "${meta.id}"

    template('parquet_to_csv.py')

    stub:
    // Exit if running this module with -profile conda / -profile mamba
    if (workflow.profile.tokenize(',').intersect(['conda', 'mamba']).size() >= 1) {
        error "PARQUET_TO_CSV module does not support Conda. Please use Docker / Singularity / Podman instead."
    }

    prefix = task.ext.prefix ?: "${meta.id}"

    """
    mkdir -p ${prefix}
    touch "${prefix}/${transcripts}.csv"

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        spatialconverter: "${task.version}"
    END_VERSIONS
    """
}
