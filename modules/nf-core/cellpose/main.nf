process CELLPOSE {
    tag "$meta.id"
    label 'process_medium'

    container "docker.io/biocontainers/cellpose:3.1.0_cv1"

    input:
    tuple val(meta), path(image)
    val(model)
    val(maskname)

    output:
    tuple val(meta), path("${meta.id}/*masks.tif"), emit: mask
    tuple val(meta), path("${meta.id}/*flows.tif"), emit: flows, optional: true
    tuple val(meta), path("${meta.id}/*seg.npy")  , emit: cells, optional: true
    path "versions.yml"                           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    // Exit if running this module with -profile conda / -profile mamba
    if (workflow.profile.tokenize(',').intersect(['conda', 'mamba']).size() >= 1) {
        error "CELLPOSE module does not support conda. Please use Docker / Singularity / Podman instead."
    }
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def model_command = model ? "--pretrained_model $model" : ""
    """
    export OMP_NUM_THREADS=${task.cpus}
    export MKL_NUM_THREADS=${task.cpus}
    export NPY_PROMOTION_STATE=legacy
    cellpose \\
        --image_path $image \\
        --save_tif \\
        $model_command \\
        $args

    mkdir -p ${prefix}
    mv *masks.tif ${prefix}/morphology.ome_${maskname}_masks.tif

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        cellpose: \$(cellpose --version | awk 'NR==2 {print \$3}')
    END_VERSIONS
    """
    
    stub:
    // Exit if running this module with -profile conda / -profile mamba
    if (workflow.profile.tokenize(',').intersect(['conda', 'mamba']).size() >= 1) {
        error "CELLPOSE module does not support conda. Please use Docker / Singularity / Podman instead."
    }
    
    def prefix = task.ext.prefix ?: "${meta.id}"
    def name = image.name
    def base = name.lastIndexOf('.') != -1 ? name[0..name.lastIndexOf('.') - 1] : name
    
    """
    mkdir -p ${prefix}
    touch ${prefix}/morphology.ome_${maskname}_masks.tif
    touch ${prefix}/morphology.ome_${maskname}_seg.npy
    touch ${base}_cp_masks.tif

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        cellpose: \$(cellpose --version | awk 'NR==2 {print \$3}')
    END_VERSIONS
    """

}
