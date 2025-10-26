process SPATIALDATA_META {
    tag "${meta.id}"
    label 'process_high_memory'

    container "khersameesh24/spatialdata:0.2.6"

    input:
    tuple val(meta), path(spatialdata_bundle, stageAs: "*"), path(xenium_bundle, stageAs: "*")
    val(outputfolder)

    output:
    tuple val(meta), path("spatialdata/${prefix}/${outputfolder}"), emit: metadata
    path ("versions.yml"), emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    // Exit if running this module with -profile conda / -profile mamba
    if (workflow.profile.tokenize(',').intersect(['conda', 'mamba']).size() >= 1) {
        exit(1, "SPATIALDATA_META module does not support Conda. Please use Docker / Singularity / Podman instead.")
    }

    prefix = task.ext.prefix ?: "${meta.id}"

    template('meta.py')

    stub:
    // Exit if running this module with -profile conda / -profile mamba
    if (workflow.profile.tokenize(',').intersect(['conda', 'mamba']).size() >= 1) {
        exit(1, "SPATIALDATA_META module does not support Conda. Please use Docker / Singularity / Podman instead.")
    }

    prefix = task.ext.prefix ?: "${meta.id}"

    """
    mkdir -p "spatialdata/${prefix}/${outputfolder}/"
    touch "spatialdata/${prefix}/${outputfolder}/fake_file.txt"

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        spatialdata: \$(echo \$( python -c "import spatialdata; print(spatialdata.__version__)" 2>&1) )
    END_VERSIONS
    """
}
