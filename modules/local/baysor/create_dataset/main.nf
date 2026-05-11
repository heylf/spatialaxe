process BAYSOR_CREATE_DATASET {
    tag "${meta.id}"
    label 'process_medium'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/97/97ecad2ae9a81cf12e8d690dfa9ca5cb0f36a0d57245f9fbb0113d15ce0e95f9/data' :
        'community.wave.seqera.io/library/baysor:0.7.1--b8eb77d1f3f580df' }"

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
