process SPOQC_ANALYSIS_OVERVIEW {
    tag "${meta.id}"
    label 'process_high_cpus'
    label 'process_xl_mem'
    label 'process_mid_time'
    label 'spoqc'


    container "heylf/spoqc_dev:0.1.1"

    input:
    tuple val(meta), path(spatialdata, stageAs: "*")
    path(annotation, stageAs: "*")
    val(step)
    path(tmp_general, stageAs: "spoQC_tmp/generalqc_output_hqcr.parquet")
    path(tmp_doublet, stageAs: "spoQC_tmp/doubletqc_output_hqcr.parquet")
    path(tmp_void, stageAs: "spoQC_tmp/voidqc_output_hqcr.parquet")
    path(tmp_cell, stageAs: "spoQC_tmp/cellqc_output_hqcr.parquet")
    path(mask_hqcr, stageAs: "spoQC_tmp/mask_raw_output_hqcr.parquet")
    path(mask_smoothed_hqcr, stageAs: "spoQC_tmp/mask_smoothed_raw_output_hqcr.parquet")
    path(traffic_light_hqcr, stageAs: "spoQC_tmp/traffic_light_output_hqcr.parquet")
    path(qv, stageAs: "spoQC_tmp/qv_density_output_hqtr")
    path(ac, stageAs: "spoQC_tmp/ac_density_output_hqtr")
    path(metrices_hqtr, stageAs: "spoQC_tmp/metrices/hqtr")
    path(mask_smoothed_hqtr, stageAs: "spoQC_tmp/mask_smoothed_raw_output_hqtr")
    path(mask_hqtr, stageAs: "spoQC_tmp/mask_raw_output_hqtr")
    path(metrices_hqpr, stageAs: "spoQC_tmp/metrices/hqpr/*")
    path(mask_smoothed_hqpr, stageAs: "spoQC_tmp/*")
    path(mask_hqpr, stageAs: "spoQC_tmp/*")

    output:
    tuple val(meta), path("report/analysis/overview")                , emit: report
    tuple val(meta), path("report/analysis/rna_qc_annotated.h5ad")   , emit: h5ad
    tuple val("${task.process}"), val('spoqc'), eval("spoqc --version 2>&1 | grep -oP '\\d+\\.\\d+\\.\\d+' || echo unknown"), topic: versions, emit: versions_spoqc

    when:
    task.ext.when == null || task.ext.when

    script:
    // Exit if running this module with -profile conda / -profile mamba
    if (workflow.profile.tokenize(',').intersect(['conda', 'mamba']).size() >= 1) {
        error("SPOQC_ANALYSIS_OVERVIEW module does not support Conda. Please use Docker / Singularity / Podman instead.")
    }

    def args = task.ext.args ?: ''
    def annotation_arg = annotation ? "-a ${annotation}" : ""

    """
    python3 -m spoqc \\
        -i ${spatialdata} \\
        -o ./ \\
        -t ./spoQC_tmp/ \\
        -n ${task.cpus} \\
        ${annotation_arg} \\
        -s ${step}  \\
        --dataset ${meta.id} \\
        ${args}
    """

    stub:
    // Exit if running this module with -profile conda / -profile mamba
    if (workflow.profile.tokenize(',').intersect(['conda', 'mamba']).size() >= 1) {
        error("SPOQC_ANALYSIS_OVERVIEW module does not support Conda. Please use Docker / Singularity / Podman instead.")
    }

    """
    mkdir -p report/analysis/overview
    touch report/analysis/rna_qc_annotated.h5ad
    """
}
