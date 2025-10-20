//
// Run cellpose on the morphology tiff
//

include { RESOLIFT                         } from '../../../modules/local/resolift/main'
include { CELLPOSE as CELLPOSE_CELLS       } from '../../../modules/nf-core/cellpose/main'
include { CELLPOSE as CELLPOSE_NUCLEI      } from '../../../modules/nf-core/cellpose/main'
include { XENIUMRANGER_IMPORT_SEGMENTATION } from '../../../modules/nf-core/xeniumranger/import-segmentation/main'

workflow CELLPOSE_RESOLIFT_MORPHOLOGY_OME_TIF {
    take:
    ch_morphology_image // channel: [ val(meta), ["path-to-morphology.ome.tiff"] ]
    ch_bundle_path      // channel: [ val(meta), ["path-to-xenium-bundle"] ]

    main:

    ch_versions = Channel.empty()
    ch_imp_seg_inputs = Channel.empty()
    ch_coordinate_space = Channel.value("pixels")

    cellpose_model = params.cellpose_model ? (Channel.fromPath(params.cellpose_model, checkIfExists: true)) : []

    // sharpen morphology tiff if param - sharpen_tiff is true
    if (params.sharpen_tiff) {

        RESOLIFT(ch_morphology_image)
        ch_versions = ch_versions.mix(RESOLIFT.out.versions)

        ch_image = RESOLIFT.out.enhanced_tiff
    }
    else {

        ch_image = ch_morphology_image
    }

    // run cellpose on morphology tiff
    CELLPOSE_CELLS(ch_image, cellpose_model, 'cells')
    ch_versions = ch_versions.mix(CELLPOSE_CELLS.out.versions)

    CELLPOSE_NUCLEI(ch_image, 'nuclei', 'nuclei')
    ch_versions = ch_versions.mix(CELLPOSE_NUCLEI.out.versions)


    // run import-segmentation with cellpose results
    if (params.nucleus_segmentation_only) {

        ch_imp_seg_inputs = ch_bundle_path
            .combine(CELLPOSE_NUCLEI.out.cells, by: 0)
            .map { meta, bundle, nuclei_seg ->
                tuple(
                    meta,
                    bundle,
                    [],
                    nuclei_seg,
                    [],
                    [],
                    [],
                    ch_coordinate_space.val,
                )
            }
        XENIUMRANGER_IMPORT_SEGMENTATION(
            ch_imp_seg_inputs
        )
        ch_versions = ch_versions.mix(XENIUMRANGER_IMPORT_SEGMENTATION.out.versions)
    }
    else {

        ch_imp_seg_inputs = ch_bundle_path
            .combine(CELLPOSE_CELLS.out.cells, by: 0)
            .combine(CELLPOSE_NUCLEI.out.cells, by: 0)
            .map { meta, bundle, cells_seg, nuclei_seg ->
                tuple(
                    meta,
                    bundle,
                    [],
                    nuclei_seg,
                    cells_seg,
                    [],
                    [],
                    ch_coordinate_space.val,
                )
            }
        XENIUMRANGER_IMPORT_SEGMENTATION(
            ch_imp_seg_inputs
        )
        ch_versions = ch_versions.mix(XENIUMRANGER_IMPORT_SEGMENTATION.out.versions)
    }

    emit:
    coordinate_space = ch_coordinate_space // channel: [ ["pixels"] ]
    redefined_bundle = XENIUMRANGER_IMPORT_SEGMENTATION.out.bundle // channel: [ val(meta), ["redefined-xenium-bundle"] ]
    versions         = ch_versions // channel: [ versions.yml ]
}
