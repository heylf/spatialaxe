process SEGGER_CREATE_DATASET {
    tag "${meta.id}"
    label 'process_high'

    container "khersameesh24/segger:0.1.0"

    input:
    tuple val(meta), path(base_dir)

    output:
    tuple val(meta), path("${prefix}/"), emit: datasetdir
    path ("versions.yml"), emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    // Exit if running this module with -profile conda / -profile mamba
    if (workflow.profile.tokenize(',').intersect(['conda', 'mamba']).size() >= 1) {
        error("SEGGER_CREATE_DATASET module does not support Conda. Please use Docker / Singularity / Podman instead.")
    }

    def args = task.ext.args ?: ''
    def script_path = "/workspace/segger_dev/src/segger/cli/create_dataset_fast.py"
    prefix = task.ext.prefix ?: "${meta.id}"

    // check for platform values
    if (!(params.format in ['xenium'])) {
        error("${params.format} is an invalid platform type.")
    }

    """
    python3 ${script_path} \\
        --base_dir ${base_dir} \\
        --data_dir ${prefix} \\
        --sample_type ${params.format} \\
        --tile_width ${params.tile_width} \\
        --tile_height ${params.tile_height} \\
        --n_workers ${task.cpus} \\
        ${args}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        segger: 0.1.0
    END_VERSIONS
    """

    stub:
    // Exit if running this module with -profile conda / -profile mamba
    if (workflow.profile.tokenize(',').intersect(['conda', 'mamba']).size() >= 1) {
        error("SEGGER_CREATE_DATASET module does not support Conda. Please use Docker / Singularity / Podman instead.")
    }

    prefix = task.ext.prefix ?: "${meta.id}"

    """
    mkdir -p ${prefix}/
    touch "${prefix}/fake_file.txt"

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        segger: 0.1.0
    END_VERSIONS
    """
}
