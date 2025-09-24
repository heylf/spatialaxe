process SEGGER_TRAIN {
    tag "$meta.id"
    label 'process_high'

    container "khersameesh24/segger:0.1.0"

    input:
    tuple val(meta), path(dataset_dir)

    output:
    tuple val(meta), path("${prefix}/trained_models"), emit: trained_models
    path("versions.yml")                             , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    // Exit if running this module with -profile conda / -profile mamba
    if (workflow.profile.tokenize(',').intersect(['conda', 'mamba']).size() >= 1) {
        error "SEGGER_TRAIN module does not support Conda. Please use Docker / Singularity / Podman instead."
    }

    def args = task.ext.args ?: ''
    def script_path = "/workspace/segger_dev/src/segger/cli/train_model.py"
    prefix = task.ext.prefix ?: "${meta.id}"

    """
    python3 ${script_path} \\
        --dataset_dir ${dataset_dir} \\
        --models_dir ${prefix}/trained_models \\
        --sample_tag ${prefix} \\
        --batch_size ${params.batch_size_train} \\
        --max_epochs ${params.max_epochs} \\
        --devices ${params.devices} \\
        --num_workers ${task.cpus} \\
        --accelerator ${params.segger_accelerator} \\
        ${args}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        segger: 0.1.0
    END_VERSIONS
    """

    stub:
    // Exit if running this module with -profile conda / -profile mamba
    if (workflow.profile.tokenize(',').intersect(['conda', 'mamba']).size() >= 1) {
        error "SEGGER_TRAIN module does not support Conda. Please use Docker / Singularity / Podman instead."
    }

    prefix = task.ext.prefix ?: "${meta.id}"

    """
    mkdir -p ${prefix}/trained_models/
    touch ${prefix}/trained_models/fakefile.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        segger: 0.1.0
    END_VERSIONS
    """
}
