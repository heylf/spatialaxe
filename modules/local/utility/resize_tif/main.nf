process RESIZE_TIF {
    tag "${meta.id}"
    label 'process_low'

    container "community.wave.seqera.io/library/scikit-image_pip_numpy_pandas_tifffile:ef6d9eac4fb80ac9"

    input:
    tuple val(meta), path(transcripts), path(mask), path(metadata)

    output:
    tuple val(meta), path("${meta.id}/resized_*.tif"), emit: resized_mask
    path ("versions.yml"), emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    // Exit if running this module with -profile conda / -profile mamba
    if (workflow.profile.tokenize(',').intersect(['conda', 'mamba']).size() >= 1) {
        error("RESIZE_TIF module does not support Conda. Please use Docker / Singularity / Podman instead.")
    }

    prefix = task.ext.prefix ?: "${meta.id}"

    template('resize_tif.py')

    stub:
    // Exit if running this module with -profile conda / -profile mamba
    if (workflow.profile.tokenize(',').intersect(['conda', 'mamba']).size() >= 1) {
        error("RESIZE_TIF module does not support Conda. Please use Docker / Singularity / Podman instead.")
    }
    prefix = task.ext.prefix ?: "${meta.id}"

    """
    mkdir -p ${prefix}
    touch "${prefix}/resized_${mask}.tif"

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        resize_tif: "1.0.0"
    END_VERSIONS
    """
}
