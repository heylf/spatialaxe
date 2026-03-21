process EXTRACT_PREVIEW_DATA {
    tag "${meta.id}"
    label 'process_low'

    container "community.wave.seqera.io/library/beautifulsoup4_pandas:d3b8b3eb86514c3c"

    input:
    tuple val(meta), path(preview_html)

    output:
    tuple val(meta), path("${prefix}/*_mqc.tsv"), emit: mqc_data
    tuple val(meta), path("${prefix}/*_mqc.png"), emit: mqc_img
    tuple val("${task.process}"), val('python'), eval('python3 --version | awk \\'\\'{print \\$2}\\'\\'''), topic: versions, emit: versions_python

    when:
    task.ext.when == null || task.ext.when

    script:
    // Exit if running this module with -profile conda / -profile mamba
    if (workflow.profile.tokenize(',').intersect(['conda', 'mamba']).size() >= 1) {
        error("EXTRACT_PREVIEW_DATA module does not support Conda. Please use Docker / Singularity / Podman instead.")
    }

    prefix = task.ext.prefix ?: "${meta.id}"

    template('extract_data.py')

    stub:
    // Exit if running this module with -profile conda / -profile mamba
    if (workflow.profile.tokenize(',').intersect(['conda', 'mamba']).size() >= 1) {
        error("EXTRACT_PREVIEW_DATA module does not support Conda. Please use Docker / Singularity / Podman instead.")
    }
    prefix = task.ext.prefix ?: "${meta.id}"

    """
    mkdir -p ${prefix}
    touch ${prefix}/noise_distribution_mqc.tsv
    touch ${prefix}/gene_structure_mqc.tsv
    touch ${prefix}/umap_mqc.tsv
    touch ${prefix}/transcript_plots_mqc.png
    touch ${prefix}/noise_level_mqc.png
    """
}
