process SPATIALDATA_MERGE {
    tag "$meta.id"
    label 'process_low'

    container "heylf/spatialdata:0.2.6"

    input:
    tuple val(meta), path(raw_bundle, stageAs: "*"), path(redefined_bundle, stageAs: "*")

    output:
    tuple val(meta), path("${prefix}/spatialdata_merged"), emit: merged_bundle
    path("versions.yml")                                 , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    // Exit if running this module with -profile conda / -profile mamba
    if (workflow.profile.tokenize(',').intersect(['conda', 'mamba']).size() >= 1) {
        exit 1, "SPATIALDATA_WRITE module does not support Conda. Please use Docker / Singularity / Podman instead."
    }

    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"

    template 'merge.py'

    stub:
    // Exit if running this module with -profile conda / -profile mamba
    if (workflow.profile.tokenize(',').intersect(['conda', 'mamba']).size() >= 1) {
        exit 1, "SPATIALDATA_WRITE module does not support Conda. Please use Docker / Singularity / Podman instead."
    }

    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    mkdir -p "${prefix}/spatialdata_merged/"
    touch "${prefix}/spatialdata_merged/fake_file.txt"

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        spatialdata: \$(echo \$( python -c "import spatialdata; print(spatialdata.__version__)" 2>&1) )
    END_VERSIONS
    """

}
