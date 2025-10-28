"""
extract_steady_timestamps.py converts marker timestamps recorded in UTC into device-specific steady
timestamps used by the EEG recordings. The module computes, for each marker
time in a task/markers CSV, the closest device steady_timestamp by
matching against a device-provided UTC.csv mapping. The result is saved
as a CSV identical to the input markers file but with new columns:
- steady_start
- steady_go
- steady_end

Usage:
    Call extract_steady_timestamps(tasks_file, utc_file, output_file, tasks)
    for each markers CSV you want to translate. For example:
    extract_steady_timestamps("Subject_01/Markers/Markers-Task-1.csv","Subject_01/Device_UTC.csv","Subject_01/Markers/Markers-Task-1-with-steady.csv",tasks=True)

Inputs:
    - tasks_file (str): Path to the markers CSV that contains columns
    'Timestamp_start', 'Timestamp_go', 'Timestamp_end', 'Word', etc.
    - utc_file (str): Path to a CSV mapping device UTC timestamps to steady timestamps.
    Must contain columns 'utc_timestamp' and 'steady_timestamp' (This is typical from BitBrain devices).
    - output_file (str): Destination path for the annotated CSV (will overwrite if exists).
    - tasks (bool): Whether the input is a task file that contains a 'Timestamp_go'
    column (True for Task-x files, False for Completed-tasks.csv).

Outputs:
    - Writes output_file CSV with the original columns plus:
        * 'steady_start' (matched steady timestamp for Timestamp_start)
        * 'steady_go' (if tasks=True, matched steady timestamp for Timestamp_go)
        * 'steady_end' (matched steady timestamp for Timestamp_end)

Details:
    - The function coercively converts Timestamp columns and utc_timestamp to numeric.
    - To match resolutions, the code multiplies marker timestamps by 1,000,000 (1e6)
    before comparing to utc_timestamp. 
    - Matching strategy: for each marker timestamp, find the utc_timestamp
    with minimal absolute difference and take its steady_timestamp.
    - The function returns None; its primary effect is saving output_file.

Edge cases, errors and recommendations:
- If multiple UTC entries are equally close, idxmin() picks the first; this
is typically acceptable but be aware for very sparse UTC mappings.

Author:
Mario Lobo (UPM)
mario.lobo.alonso@alumnos.upm.es
Version:
27-10-2025
"""


import pandas as pd

def extract_steady_timestamps(tasks_file: str, utc_file: str, output_file: str, tasks: bool):
    """
    Associates the UTC timestaps in markers' csvs with the respective steady_timestamp indicated in UTC.csv of each device
    
    Args:
        tasks_file (str): Path to the csv with the markers in UTC format
        utc_file (str): Path to the CSV with the association between UTC and steady_timestamp of the device
        output_file (str): File path where the new CSV will be stored
        tasks (bool): Indicates if we are translating "Tasks-completed.csv" (false) or "Task-x.csv" (true)
    """

    """
    Map UTC marker timestamps to device steady_timestamps and save annotated CSV.
    For each marker row in tasks_file, find the closest `utc_timestamp` entry in utc_file
    and record the corresponding `steady_timestamp`. Adds `steady_start`, optionally `steady_go`,
    and `steady_end` columns, then writes the augmented DataFrame to output_file.

    Args:
        tasks_file (str): Path to the markers CSV. Expected columns:
                        'Timestamp_start', 'Timestamp_end' and (if tasks=True), 'Timestamp_go'.
        utc_file (str): Path to CSV mapping device UTC timestamps to steady timestamps.
                        Expected columns: 'utc_timestamp' (numeric) and 'steady_timestamp'.
        output_file (str): Path where the resulting CSV will be saved (overwrites).
        tasks (bool): If True, function will process 'Timestamp_go' and produce
                    a 'steady_go' column. If False, 'steady_go' is not produced.

    Returns:
        None. The function writes output_file and prints its path.

    Example:
        extract_steady_timestamps(
            "Subject_01/Markers/Markers-Task-1.csv",
            "Subject_01/Device_UTC.csv",
            "Subject_01/Markers/Markers-Task-1-with-steady.csv",
            tasks=True
        )
    """

    # Loading data
    tasks_df = pd.read_csv(tasks_file, sep=',')
    utc_df = pd.read_csv(utc_file, sep=',')
    
    # Assuring timestamp columns are a numeric type
    tasks_df["Timestamp_start"] = pd.to_numeric(tasks_df["Timestamp_start"], errors="coerce")
    if tasks:
        tasks_df["Timestamp_go"] = pd.to_numeric(tasks_df["Timestamp_go"], errors="coerce")
    tasks_df["Timestamp_end"] = pd.to_numeric(tasks_df["Timestamp_end"], errors="coerce")
    utc_df["utc_timestamp"] = pd.to_numeric(utc_df["utc_timestamp"], errors="coerce")

    # Inicialating memory for each moment traduction
    steady_start = []
    if tasks:
        steady_go = []
    steady_end = []
    
    for _, row in tasks_df.iterrows():
        # Find the index with the utc_timestamp the nearest to timestamp-start in UTC
        if not pd.isna(row["Timestamp_start"]):
            idx_start = (utc_df["utc_timestamp"] - row["Timestamp_start"]*1000000).abs().idxmin()
            #Multiplying by 10^6 because we are using different resolutions. That means, the UTC of the device is 16 digit length, while markers are 10 digit lenght
            steady_start.append(utc_df.loc[idx_start, "steady_timestamp"])
        else:
            steady_start.append(None)  # Error managment

        if tasks:
            # Find the index with the utc_timestamp the nearest to timestamp-go in UTC
            if not pd.isna(row["Timestamp_go"]):
                idx_go = (utc_df["utc_timestamp"] - row["Timestamp_go"]*1000000).abs().idxmin() 
                steady_go.append(utc_df.loc[idx_go, "steady_timestamp"])
            else:
                steady_go.append(None)  # Error management

        # Find the index with the utc_timestamp the nearest to timestamp-end in UTC
        if not pd.isna(row["Timestamp_end"]):
            idx_end = (utc_df["utc_timestamp"] - row["Timestamp_end"]*1000000).abs().idxmin()
            steady_end.append(utc_df.loc[idx_end, "steady_timestamp"])
        else:
            steady_end.append(None)  # Error management
    
    # Adding the steady_timestamps to the final DataFrame
    tasks_df["steady_start"] = steady_start
    if tasks:
        tasks_df["steady_go"] = steady_go
    tasks_df["steady_end"] = steady_end
    
    # Saving the final file with the steady_timestamps associated
    tasks_df.to_csv(output_file, sep=',', index=False)
    print(f"Archivo guardado: {output_file}")