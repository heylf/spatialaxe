process SEGGER_PREDICT {
    tag "${meta.id}"
    label 'process_gpu'

    container "khersameesh24/segger:0.1.0"

    input:
    tuple val(meta), path(segger_dataset)
    path models_dir
    path transcripts

    output:
    tuple val(meta), path("${prefix}/benchmarks_dir"), emit: benchmarks
    tuple val(meta), path("${prefix}/benchmarks_dir/*/segger_transcripts.parquet"), emit: transcripts
    path ("versions.yml"), emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    // Exit if running this module with -profile conda / -profile mamba
    if (workflow.profile.tokenize(',').intersect(['conda', 'mamba']).size() >= 1) {
        error("SEGGER_PREDICT module does not support Conda. Please use Docker / Singularity / Podman instead.")
    }

    def args = task.ext.args ?: ''
    def script_path = "/workspace/segger_dev/src/segger/cli/predict_fast.py"
    prefix = task.ext.prefix ?: "${meta.id}"

    """
    python3 ${script_path} \\
        --models_dir ${models_dir} \\
        --segger_data_dir ${segger_dataset} \\
        --transcripts_file ${transcripts} \\
        --benchmarks_dir ${prefix}/benchmarks_dir \\
        --batch_size ${params.batch_size_predict} \\
        --use_cc ${params.cc_analysis} \\
        --knn_method ${params.segger_knn_method} \\
        --num_workers ${task.cpus} \\
        ${args}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        segger: 0.1.0
    END_VERSIONS
    """

    stub:
    // Exit if running this module with -profile conda / -profile mamba
    if (workflow.profile.tokenize(',').intersect(['conda', 'mamba']).size() >= 1) {
        error("SEGGER_PREDICT module does not support Conda. Please use Docker / Singularity / Podman instead.")
    }

    prefix = task.ext.prefix ?: "${meta.id}"

    """
    mkdir -p "${prefix}/benchmarks_dir"
    touch "${prefix}/fake_file.txt"

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        segger: 0.1.0
    END_VERSIONS
    """
}
