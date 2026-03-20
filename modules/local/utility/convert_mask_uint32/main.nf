/*
 * CONVERT_MASK_UINT32: Convert segmentation mask to uint32 dtype.
 *
 * XeniumRanger import-segmentation requires uint32 masks.
 * StarDist outputs int32 labels by default.
 *
 * Input:
 *   - meta: Sample metadata map
 *   - mask: Segmentation mask TIFF (any integer dtype)
 *
 * Output:
 *   - mask: uint32 segmentation mask TIFF
 *   - versions: Software versions
 */
process CONVERT_MASK_UINT32 {
    tag "${meta.id}"
    label 'process_low'

    conda "conda-forge::python=3.12 conda-forge::tifffile conda-forge::numpy"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/d9/d964e0bef867bb2ff1a309c9c087d8d83ac734ce3aa315dd8311d4c1bfdafd8e/data' :
        'community.wave.seqera.io/library/python_pip_imagecodecs_nvidia-cublas-cu12_pruned:b668bcb6d531d350' }"

    input:
    tuple val(meta), path(mask)

    output:
    tuple val(meta), path("${prefix}_uint32_mask.tif"), emit: mask
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    python3 - ${mask} ${prefix}_uint32_mask.tif <<'PYEOF'
import sys, tifffile, numpy as np

mask_path, output_path = sys.argv[1], sys.argv[2]
mask = tifffile.imread(mask_path)
print(f'Input dtype: {mask.dtype}, shape: {mask.shape}, labels: {mask.max()}')
tifffile.imwrite(output_path, mask.astype(np.uint32))
print(f'Output dtype: uint32')
PYEOF

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version | awk '{print \$2}')
        tifffile: \$(python -c "import tifffile; print(tifffile.__version__)")
        numpy: \$(python -c "import numpy; print(numpy.__version__)")
    END_VERSIONS
    """

    stub:
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}_uint32_mask.tif

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: "3.12.0"
        tifffile: "2026.3.3"
        numpy: "2.0.0"
    END_VERSIONS
    """
}
