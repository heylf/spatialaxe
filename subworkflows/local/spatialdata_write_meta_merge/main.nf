//
// generate spatialdata object from the spatialxe layers
//

include { SPATIALDATA_META                                        } from '../../../modules/local/spatialdata/meta/main'
include { SPATIALDATA_WRITE as SPATIALDATA_WRITE_RAW_BUNDLE       } from '../../../modules/local/spatialdata/write/main'
include { SPATIALDATA_MERGE as SPATIALDATA_MERGE_RAW_REDEFINED    } from '../../../modules/local/spatialdata/merge/main'
include { SPATIALDATA_WRITE as SPATIALDATA_WRITE_REDEFINED_BUNDLE } from '../../../modules/local/spatialdata/write/main'

workflow SPATIALDATA_WRITE_META_MERGE {
    take:
    ch_bundle_path      // channel: [ val(meta), [ "path-to-xenium-bundle" ] ]
    ch_redefined_bundle // channel: [ val(meta), [ "redefined-xenium-bundle" ] ]
    ch_coordinate_space // channel: [ "pixels" or "microns" ]

    main:

    ch_segmented_object = channel.empty()

    // check segmentation - only nuclei, cells or both cells & nuclei
    if (params.mode == 'image') {

        if (params.nucleus_segmentation_only && params.cell_segmentation_only) {
            ch_segmented_object = channel.value('cells_and_nuclei')
        }
        else if (params.nucleus_segmentation_only) {
            ch_segmented_object = channel.value('nuclei')
        }
        else if (params.cell_segmentation_only) {
            ch_segmented_object = channel.value('cells')
        }
        else {
            ch_segmented_object = channel.value([])
        }
    }

    // set all boundaries as false - default
    if (params.mode == 'coordinate') {
        ch_segmented_object = channel.value([])
    }

    // write spatialdata object from the raw xenium bundle
    SPATIALDATA_WRITE_RAW_BUNDLE(
        ch_bundle_path,
        'raw_bundle',
        ch_segmented_object,
        ch_coordinate_space,
    )


    // write spatialdata object after running IMP_SEG
    SPATIALDATA_WRITE_REDEFINED_BUNDLE(
        ch_redefined_bundle,
        'redefined_bundle',
        ch_segmented_object,
        ch_coordinate_space,
    )


    // merge raw & redefined spatialdata objects
    SPATIALDATA_MERGE_RAW_REDEFINED(
        SPATIALDATA_WRITE_RAW_BUNDLE.out.spatialdata.combine(ch_redefined_bundle, by: 0),
        'merged_bundle'
    )


    // write metadata with spatialdata object
    SPATIALDATA_META(
        SPATIALDATA_MERGE_RAW_REDEFINED.out.merged_bundle.combine(ch_bundle_path, by: 0),
        'metadata'
    )

    emit:
    sd_raw_bundle       = SPATIALDATA_WRITE_RAW_BUNDLE.out.spatialdata // channel: [ val(meta), "spatialdata_raw" ]
    sd_redefined_bundle = SPATIALDATA_WRITE_REDEFINED_BUNDLE.out.spatialdata // channel: [ val(meta), "spatialdata_redefined" ]
    sd_merged_bundle    = SPATIALDATA_MERGE_RAW_REDEFINED.out.merged_bundle // channel: [ val(meta), "spatialdata_merged" ]
    sd_metadata         = SPATIALDATA_META.out.metadata // channel: [ val(meta), "spatialdata_meta" ]
}
