//
// Run xeniumranger import-segmentation
//

include { XENIUMRANGER_IMPORT_SEGMENTATION as IMP_SEG_COUNT_MATRIX_EXP_DISTANCE } from '../../../modules/nf-core/xeniumranger/import-segmentation/main'
include { XENIUMRANGER_IMPORT_SEGMENTATION as IMP_SEG_POLYGON_GEOJSON_INPUT     } from '../../../modules/nf-core/xeniumranger/import-segmentation/main'
include { XENIUMRANGER_IMPORT_SEGMENTATION as IMP_SEG_TRANS_MATRIX_INPUT        } from '../../../modules/nf-core/xeniumranger/import-segmentation/main'


workflow XENIUMRANGER_IMPORT_SEGMENTATION_REDEFINE_BUNDLE {

    take:

    ch_bundle_path // channel: [ val(meta), [ "path-to-xenium-bundle" ] ]

    main:

    ch_versions = Channel.empty()
    ch_redefined_bundle = Channel.empty()
    ch_coordinate_space = Channel.empty()

    cells = ch_bundle_path.map {
        meta, bundle -> return [ meta, bundle + "/cells.zarr.zip" ]
    }

    // scenario - 1 change nuclear expansion distance / create a nucleus-only count matrix(--expansion_distance=0)
    if ( params.expansion_distance == 0 || params.expansion_distance != 5 ) {
        ch_coordinate_space = "microns"
        ch_imp_seg_inputs = ch_bundle_path
                                .combine(cells, by:0)
                                .map {
                                    meta, bundle, cells_zarr -> tuple (
                                        meta,                    // meta
                                        bundle,                  // bundle
                                        [],                      // coordinate_transform
                                        cells_zarr,              // nuclei
                                        [],                      // cells
                                        [],                      // transcript_assignment
                                        [],                      // viz_polygons
                                        ch_coordinate_space.val  // units
                                    )
                                }

        IMP_SEG_COUNT_MATRIX_EXP_DISTANCE (
            ch_imp_seg_inputs
        )
        ch_redefined_bundle = IMP_SEG_COUNT_MATRIX_EXP_DISTANCE.out.bundle

        ch_versions = ch_versions.mix ( IMP_SEG_COUNT_MATRIX_EXP_DISTANCE.out.versions )
    }

    // scenario - 2 polygon input - geojson format (from QuPath)
    if ( params.qupath_polygons && params.nucleus_segmentation_only ) {

        ch_coordinate_space = "microns"
        ch_imp_seg_inputs = ch_bundle_path
                                .combine(params.qupath_polygons)
                                .map {
                                    meta, bundle, polygons_geojson  -> tuple (
                                        meta,                    // meta
                                        bundle,                  // bundle
                                        [],                      // coordinate_transform
                                        polygons_geojson,        // nuclei
                                        [],                      // cells
                                        [],                      // transcript_assignment
                                        [],                      // viz_polygons
                                        ch_coordinate_space.val  // units
                                    )
                                }

        IMP_SEG_POLYGON_GEOJSON_INPUT (
            ch_imp_seg_inputs
        )
        ch_redefined_bundle = IMP_SEG_POLYGON_GEOJSON_INPUT.out.bundle

        ch_versions = ch_versions.mix ( IMP_SEG_POLYGON_GEOJSON_INPUT.out.versions )

    } else if ( params.qupath_polygons ) {

        ch_coordinate_space = "microns"
        ch_imp_seg_inputs = ch_bundle_path
                                .combine(params.qupath_polygons)
                                .map {
                                    meta, bundle, polygons_geojson -> tuple (
                                        meta,                    // meta
                                        bundle,                  // bundle
                                        [],                      // coordinate_transform
                                        polygons_geojson,        // nuclei
                                        polygons_geojson,        // cells
                                        [],                      // transcript_assignment
                                        [],                      // viz_polygons
                                        ch_coordinate_space.val  // units
                                    )
                                }

        IMP_SEG_POLYGON_GEOJSON_INPUT (
            ch_imp_seg_inputs
        )
        ch_redefined_bundle = IMP_SEG_POLYGON_GEOJSON_INPUT.out.bundle

        ch_versions = ch_versions.mix ( IMP_SEG_POLYGON_GEOJSON_INPUT.out.versions )

    }

    // scenario 3 - mask input - included in the cellpose subworkflow

    // scenario 4 - transcript assignment input - included in the baysor & proseg subworkflows

    // scenario 5 - transformation matrix input
    if ( params.qupath_polygons && params.alignment_csv ) {

        ch_imp_seg_inputs = ch_bundle_path
                                .combine(params.qupath_polygins)
                                .combine(params.alignment_csv)
                                .map {
                                    meta, bundle, polygons_geojson, alignment_csv -> tuple (
                                        meta,                    // meta
                                        bundle,                  // bundle
                                        alignment_csv,                      // coordinate_transform
                                        polygons_geojson,        // nuclei
                                        polygons_geojson,        // cells
                                        [],                      // transcript_assignment
                                        [],                      // viz_polygons
                                        ch_coordinate_space.val  // units
                                    )
                                }

        IMP_SEG_TRANS_MATRIX_INPUT (
            ch_imp_seg_inputs
        )
        ch_redefined_bundle = IMP_SEG_TRANS_MATRIX_INPUT.out.bundle

        ch_versions = ch_versions.mix ( IMP_SEG_TRANS_MATRIX_INPUT.out.versions )
    }


    emit:

    redefined_bundle  = ch_redefined_bundle // channel: [ val(meta), ["redefined-xenium-bundle"] ]

    coordinate_space = ch_coordinate_space  // channel: [ ["pixels"] ]

    versions          = ch_versions         // channel: [ versions.yml ]
}
