#!/usr/bin/env python3

import pandas as pd

def get_coordinates(parquet_path: str):
    """
    Reads a Parquet file and returns (x_min, x_max, y_min, y_max)
    based on the coordinate columns.

    Args:
        parquet_path (str): Path to transcripts.parquet
    """

    df = pd.read_parquet(parquet_path, engine='pyarrow')

    # Identify coordinate columns
    possible_x = [c for c in df.columns if 'x' in c.lower()]
    possible_y = [c for c in df.columns if 'y' in c.lower()]

    if not possible_x or not possible_y:
        raise ValueError("Could not find coordinate columns (expected names like x_location, y_location).")

    x_col, y_col = possible_x[0], possible_y[0]

    return (
        float(df[x_col].min()),
        float(df[x_col].max()),
        float(df[y_col].min()),
        float(df[y_col].max())
    )


# Example usage
if __name__ == "__main__":

    transcripts = "${transcripts}"
    get_coordinates(transcripts)
