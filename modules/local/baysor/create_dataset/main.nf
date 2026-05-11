process BAYSOR_CREATE_DATASET {
    tag "${meta.id}"
    label 'process_medium'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/ac/ac0d3ff0eccb4d861d4bccff00a0582f610ef2e8e37fc684db6b9436193a0bb6/data' :
        'community.wave.seqera.io/library/baysor_python:3ef186887d7a5e32' }"

    input:
    tuple val(meta), path(transcripts)
    val sample_fraction

    output:
    tuple val(meta), path("${prefix}/sampled_transcripts.csv"), emit: sampled_transcripts
    tuple val("${task.process}"), val('python'), eval("python3 --version | sed 's/Python //'"), topic: versions, emit: versions_python

    when:
    task.ext.when == null || task.ext.when

    script:
    // Exit if running this module with -profile conda / -profile mamba
    if (workflow.profile.tokenize(',').intersect(['conda', 'mamba']).size() >= 1) {
        error("BAYSOR_CREATE_DATASET module does not support Conda. Please use Docker / Singularity / Podman instead.")
    }

    prefix = task.ext.prefix ?: "${meta.id}"

    """
    baysor_create_dataset.py \\
        --transcripts ${transcripts} \\
        --sample-fraction ${sample_fraction} \\
        --prefix ${prefix}
    """

    stub:
    // Exit if running this module with -profile conda / -profile mamba
    if (workflow.profile.tokenize(',').intersect(['conda', 'mamba']).size() >= 1) {
        error("BAYSOR_CREATE_DATASET module does not support Conda. Please use Docker / Singularity / Podman instead.")
    }

    prefix = task.ext.prefix ?: "${meta.id}"

    """
    mkdir -p ${prefix}
    touch "${prefix}/sampled_transcripts.csv"
    """
}
