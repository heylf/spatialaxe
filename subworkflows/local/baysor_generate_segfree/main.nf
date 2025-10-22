//
// Run baysor segfree
//

include { BAYSOR_SEGFREE } from '../../../modules/local/baysor/segfree/main'
// include a module to process the output loom file with scapny or anndata

workflow BAYSOR_GENERATE_SEGFREE {
    take:
    ch_transcripts_parquet // channel: [ val(meta), ["transcripts.parquet"] ]
    ch_config              // channel: [ ["path-to-xenium.toml"] ]

    main:

    ch_versions = Channel.empty()

    // run baysor segfree
    ch_baysor_segfree_input = ch_transcripts_parquet
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
    ch_versions = ch_versions.mix(BAYSOR_SEGFREE.out.versions)

    emit:
    ncvs     = BAYSOR_SEGFREE.out.ncvs // channel: [ val(meta), ["ncvs.loom"] ]
    versions = ch_versions // channel: [ versions.yml ]
}
