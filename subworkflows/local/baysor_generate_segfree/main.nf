//
// Run baysor segfree
//

include { BAYSOR_PREPROCESS_TRANSCRIPTS } from '../../../modules/local/baysor/preprocess/main'
include { BAYSOR_SEGFREE                } from '../../../modules/local/baysor/segfree/main'
// include a module to process the output loom file with scapny or anndata

workflow BAYSOR_GENERATE_SEGFREE {
    take:
    ch_transcripts_file // channel: [ val(meta), ["transcripts.parquet"] ]
    ch_config              // channel: [ ["path-to-xenium.toml"] ]

    main:

    ch_transcripts = channel.empty()

    // Always preprocess transcripts.parquet to CSV for Baysor 0.7.1 compatibility.
    // Baysor's Julia Parquet.jl cannot read zstd-compressed parquet files from Xenium bundles.
    // Also applies optional spatial/QV filtering when params.filter_transcripts is true.
    BAYSOR_PREPROCESS_TRANSCRIPTS(
        ch_transcripts_file,
        params.min_qv,
        params.max_x,
        params.min_x,
        params.max_y,
        params.min_y,
    )
    ch_transcripts = BAYSOR_PREPROCESS_TRANSCRIPTS.out.transcripts_file

    // run baysor segfree
    ch_baysor_segfree_input = ch_transcripts
                                .combine(ch_config)
                                .map { meta, transcripts, config ->
                                    tuple(
                                        meta,
                                        transcripts,
                                        config
                                    )
                                }
    BAYSOR_SEGFREE(
        ch_baysor_segfree_input
    )
    
    emit:
    ncvs     = BAYSOR_SEGFREE.out.ncvs // channel: [ val(meta), ["ncvs.loom"] ]
}
