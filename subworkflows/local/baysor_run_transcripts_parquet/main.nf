//
// Run baysor run and import-segmentation
//

// include { SPLIT_TRANSCRIPTS             } from '../../../modules/local/utility/split_transcripts/main'
include { BAYSOR_RUN                       } from '../../../modules/local/baysor/run/main'
include { BAYSOR_PREPROCESS_TRANSCRIPTS    } from '../../../modules/local/baysor/preprocess/main'
include { XENIUMRANGER_IMPORT_SEGMENTATION } from '../../../modules/nf-core/xeniumranger/import-segmentation/main'


workflow BAYSOR_RUN_TRANSCRIPTS_PARQUET {

    take:

    ch_bundle_path          // channel: [ val(meta), ["xenium-bundle"] ]
    ch_transcripts_parquet  // channel: [ val(meta), ["transcripts.csv.parquet"] ]
    ch_config               // channel: ["path-to-xenium.toml"]

    main:

    ch_versions             = Channel.empty()

    ch_transcripts          = Channel.empty()
    // ch_splits_csv           = Channel.empty()

    ch_redefined_bundle     = Channel.empty()
    ch_coordinate_space     = Channel.value("microns")

    // TODO: run baysor in parallel - next release issue
    // generate splits
    // SPLIT_TRANSCRIPTS (
    //     ch_transcripts_parquet,
    //     params.x_bins,
    //     params.y_bins
    // )
    // ch_versions = ch_versions.mix ( SPLIT_TRANSCRIPTS.out.versions )

    // ch_splits_csv = SPLIT_TRANSCRIPTS.out.splits_csv


    // Set splits.csv into tuple queue channel
    // Channel
    //     ch_splits_csv
    //     .flatMap { meta, splits_file ->
    //         splits_file.splitCsv(header: true).collect { row ->
    //             tuple(meta, row.tile_id, row.x_min, row.x_max, row.y_min, row.y_max)
    //         }
    //     }
    //     .set { ch_splits } // channel: [ val(tile_id), val(x_min), val(x_max), val(y_min), val(y_max) ]


    //Add in sample path for each split value
    // transcripts_input = ch_transcripts_parquet.combine(ch_splits, by: 0)


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


    // run baysor with the filtered transcripts.parquet
    BAYSOR_RUN (
        ch_transcripts,
        [],
        ch_config,
        30
    )
    ch_versions = ch_versions.mix ( BAYSOR_RUN.out.versions )


    // run xeniumranger import-segmentation
    ch_segmentation = BAYSOR_RUN.out.segmentation
    ch_segmentation_csv = ch_segmentation.map { _meta, seg_csv, _seg_json ->
        return [ seg_csv ]
    }
    ch_polygons2d = ch_segmentation.map { _meta, _seg_csv, seg_json ->
       return [ seg_json ]
    }

    XENIUMRANGER_IMPORT_SEGMENTATION (
        ch_bundle_path,
        [],
        [],
        [],
        ch_segmentation_csv,
        ch_polygons2d,
        ch_coordinate_space
    )
    ch_versions = ch_versions.mix( XENIUMRANGER_IMPORT_SEGMENTATION.out.versions )

    ch_redefined_bundle = XENIUMRANGER_IMPORT_SEGMENTATION.out.bundle

    emit:

    coordinate_space = ch_coordinate_space    // channel: [ ["microns"] ]

    redefined_bundle = ch_redefined_bundle    // channel: [ val(meta), "redefined-xenium-bundle" ]

    versions = ch_versions                    // channel: [ versions.yml ]
}
