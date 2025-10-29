process CLEAN_PREVIEW_HTML {
    tag "${meta.id}"
    label 'process_low'

    container "community.wave.seqera.io/library/beautifulsoup4_procs:3f09125465990b35"

    input:
    tuple val(meta), path(preview_html)

    output:
    tuple val(meta), path("${prefix}/preview_mqc.html"), emit: mqc_html
    path ("versions.yml"), emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    // Exit if running this module with -profile conda / -profile mamba
    if (workflow.profile.tokenize(',').intersect(['conda', 'mamba']).size() >= 1) {
        error("CLEAN_HTML module does not support Conda. Please use Docker / Singularity / Podman instead.")
    }

    prefix = task.ext.prefix ?: "${meta.id}"

    template('clean_html.py')

    stub:
    // Exit if running this module with -profile conda / -profile mamba
    if (workflow.profile.tokenize(',').intersect(['conda', 'mamba']).size() >= 1) {
        error("CLEAN_HTML module does not support Conda. Please use Docker / Singularity / Podman instead.")
    }
    prefix = task.ext.prefix ?: "${meta.id}"

    """
    mkdir -p ${prefix}
    touch ${prefix}/preview_mqc.html

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        CLEAN_HTML: "1.0.0"
    END_VERSIONS
    """
}
