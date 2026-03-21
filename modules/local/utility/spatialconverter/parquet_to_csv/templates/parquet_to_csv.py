#!/usr/bin/env python


import pandas as pd
from pathlib import Path


def convert_parquet(
    transcripts: Path,
    extension: str = '.csv',
    prefix: str = ""
    ) -> None:

    df = pd.read_parquet(transcripts, engine='pyarrow')

    Path(prefix).mkdir(parents=True, exist_ok=True)

    if extension == ".gz":
        output = transcripts.replace(".parquet", ".csv.gz")
        df.to_csv(f"{prefix}/{output}", compression='gzip', index=False)
    else:
        output = transcripts.replace(".parquet", ".csv")
        df.to_csv(f"{prefix}/{output}", index=False)

    return None


if __name__ == '__main__':

    transcripts: str = "${transcripts}"
    extension: str = "${extension}"
    prefix: str = "${meta.id}"

    # generate transcripts.csv(.gz)
    convert_parquet(
        transcripts=transcripts,
        extension=extension,
        prefix=prefix
    )
