//
// Run baysor run and import-segmentation
//

// include { SPLIT_TRANSCRIPTS             } from '../../../modules/local/utility/split_transcripts/main'
include { BAYSOR_RUN                       } from '../../../modules/local/baysor/run/main'
include { BAYSOR_PREPROCESS_TRANSCRIPTS    } from '../../../modules/local/baysor/preprocess/main'
include { XENIUMRANGER_IMPORT_SEGMENTATION } from '../../../modules/nf-core/xeniumranger/import-segmentation/main'


workflow BAYSOR_RUN_TRANSCRIPTS_PARQUET {
    take:
    ch_bundle_path         // channel: [ val(meta), ["xenium-bundle"] ]
    ch_transcripts_parquet // channel: [ val(meta), ["transcripts.parquet"] ]
    ch_config              // channel: ["path-to-xenium.toml"]

    main:

    ch_versions = Channel.empty()

    ch_transcripts = Channel.empty()
    // ch_splits_csv           = Channel.empty()

    ch_redefined_bundle = Channel.empty()
    ch_coordinate_space = Channel.value("microns")

    // TODO: run baysor in parallel - next release issue

    // filter transcripts.parquet based on thresholds
    if (params.filter_transcripts) {

        BAYSOR_PREPROCESS_TRANSCRIPTS(
            ch_transcripts_parquet,
            params.min_qv,
            params.max_x,
            params.min_x,
            params.max_y,
            params.min_y,
        )
        ch_versions = ch_versions.mix(BAYSOR_PREPROCESS_TRANSCRIPTS.out.versions)

        ch_transcripts = BAYSOR_PREPROCESS_TRANSCRIPTS.out.transcripts_parquet
    }
    else {

        ch_transcripts = ch_transcripts_parquet
    }


    // run baysor with the filtered transcripts.parquet
    ch_baysor_input = ch_transcripts
        .combine(ch_config)
        .map { meta, transcripts, config ->
            tuple(
                meta,
                transcripts,
                [],
                config,
                30,
            )
        }
    BAYSOR_RUN(ch_baysor_input)
    ch_versions = ch_versions.mix(BAYSOR_RUN.out.versions)


    // run xeniumranger import-segmentation
    ch_imp_seg_inputs = ch_bundle_path
        .combine(BAYSOR_RUN.out.segmentation, by: 0)
        .map { meta, bundle, segmentation_csv, polygons2d ->
            tuple(
                meta,
                bundle,
                [],
                [],
                [],
                segmentation_csv,
                polygons2d,
                ch_coordinate_space.val,
            )
        }

    XENIUMRANGER_IMPORT_SEGMENTATION(
        ch_imp_seg_inputs
    )
    ch_versions = ch_versions.mix(XENIUMRANGER_IMPORT_SEGMENTATION.out.versions)

    ch_redefined_bundle = XENIUMRANGER_IMPORT_SEGMENTATION.out.bundle

    emit:
    coordinate_space = ch_coordinate_space // channel: [ ["microns"] ]
    redefined_bundle = ch_redefined_bundle // channel: [ val(meta), "redefined-xenium-bundle" ]
    versions         = ch_versions // channel: [ versions.yml ]
}
