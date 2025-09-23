//
// Run baysor run & import-segmentation
//

include { BAYSOR_PREPROCESS_TRANSCRIPTS    } from '../../../modules/local/baysor/preprocess/main'
include { BAYSOR_RUN                       } from '../../../modules/local/baysor/run/main'
include { XENIUMRANGER_IMPORT_SEGMENTATION } from '../../../modules/nf-core/xeniumranger/import-segmentation/main'


workflow BAYSOR_RUN_PRIOR_SEGMENTATION_MASK {

    take:

    ch_bundle_path         // channel: [ val(meta), ["path-to-xenium-bundle"] ]
    ch_transcripts_parquet // channel: [ val(meta), ["path-to-transcripts.parquet"] ]
    ch_segmentation_mask   // channel: [ ["path-to-prior-segmentation-mask"] ]
    ch_config              // channel: [ "path-to-xenium.toml" ]

    main:

    ch_versions             = Channel.empty()

    ch_transcripts          = Channel.empty()

    ch_redefined_bundle     = Channel.empty()
    ch_coordinate_space     = Channel.value("microns")

    // filter transcripts.parquet based on thresholds
    if ( params.filter_transcripts ) {

        BAYSOR_PREPROCESS_TRANSCRIPTS (
            ch_transcripts_parquet,
            params.min_qv,
            params.max_x,
            params.min_x,
            params.max_y,
            params.min_y
        )
        ch_versions = ch_versions.mix ( BAYSOR_PREPROCESS_TRANSCRIPTS.out.versions )

        ch_transcripts = BAYSOR_PREPROCESS_TRANSCRIPTS.out.transcripts_parquet

    } else {

        ch_transcripts = ch_transcripts_parquet
    }

    // run baysor with morphology.tiff
    BAYSOR_RUN (
        ch_transcripts,
        ch_segmentation_mask,
        ch_config,
        30
    )
    ch_versions = ch_versions.mix( BAYSOR_RUN.out.versions )

    // run import-segmentation with baysor outs
    ch_imp_seg_inputs = ch_bundle_path
                            .combine(BAYSOR_RUN.out.segmentation, by: 0)
                            .map {
                                meta, bundle, segmentation_outs ->
                                def ( _meta, segmentation_csv, polygons2d ) = segmentation_outs
                                tuple (
                                    meta,                    // meta
                                    bundle,                  // bundle
                                    [],                      // coordinate_transform
                                    [],                      // nuclei
                                    [],                      // cells
                                    segmentation_csv,        // transcript_assignment
                                    polygons2d,              // viz_polygons
                                    ch_coordinate_space.val  // units
                                )
                            }

    XENIUMRANGER_IMPORT_SEGMENTATION (
        ch_imp_seg_inputs
    )
    ch_versions = ch_versions.mix ( XENIUMRANGER_IMPORT_SEGMENTATION.out.versions )

    ch_redefined_bundle = XENIUMRANGER_IMPORT_SEGMENTATION.out.bundle

    emit:

    coordinate_space = ch_coordinate_space    // channel: [ "microns" ]

    redefined_bundle = ch_redefined_bundle    // channel: [ val(meta), ["redefined-xenium-bundle"] ]

    versions = ch_versions                    // channel: [ versions.yml ]
}
