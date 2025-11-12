"""
trim_real_data.py performs the initial trimming and reorganization steps for BitBrain EEG
sessions. The script clones the raw recording folder to a safe output
location, identifies the device data subfolder (BBT-E32*), and trims the
recorded EEG signal so that only samples between the session start and
end (with a configurable margin) are kept. This avoids early recording
segments with poor signal quality while preserving task-aligned data.

High-level steps:
    1. Normalize input/output paths and validate input exists.
    2. Copy the entire input folder tree to the output_path (safe working copy).
    3. Find the session data subfolder matching BBT-E32* and locate:
        - UTC.csv (mapping device utc_timestamp -> steady_timestamp)
        - EEG.csv (continuous EEG with steady_timestamp column)
        - Markers/Tasks-Completed.csv (task start/end timestamps)
    4. Determine the steady_timestamp corresponding to Task-0 start and the
    final task end by matching UTC timestamps (uses a nearest-neighbor match
    after scaling marker timestamps by 1e6 to align units).
    5. Convert those steady timestamps to row indices within EEG.csv, apply
    the provided margin (in samples) and trim the EEG rows to that window.
    6. Overwrite the session EEG.csv in the output folder with the trimmed data.

Usage:
    Call execute(parent_path, output_path, margin) from a driver script or GUI.
    Example:
    execute("C:/data/raw/Subject_01/Session_01", "C:/data/working/Subject_01/Session_01", margin=512)

Inputs:
    - parent_path (str): Path to the original session folder (will be copied).
    - output_path (str): Destination folder where a working copy is created and trimmed.
    - margin (int): Number of samples to subtract before the start and add after the end
    (applied to row indices derived from steady timestamps).

Outputs:
    - Copies the entire parent_path folder tree to output_path (uses shutil.copytree with dirs_exist_ok=True).
    - Overwrites EEG.csv within the working copy with a trimmed version (rows retained between computed start and end indices).

Details:
    - The function expects:
        * Markers/Tasks-Completed.csv with columns 'Timestamp_start' and 'Timestamp_end'.
        * UTC.csv with columns 'utc_timestamp' and 'steady_timestamp'.
        * EEG.csv with a 'steady_timestamp' column and one row per sample.
    - Marker timestamps in Tasks-Completed.csv are multiplied by 1e6 before matching to utc_timestamp (this aligns differing timestamp resolutions used in the project).
    - The code selects the first subfolder matching BBT-E32* under output_path; if multiple matching folders exist, only the first is used.
    - shutil.copytree(..., dirs_exist_ok=True) requires Python >=3.8.
 
Author:
Mario Lobo (UPM)
mario.lobo.alonso@alumnos.upm.es
Version:
28-10-2025
"""



#Libraries can be installed with pip -r requeriments.txt
import glob
import json
import os, shutil
import pandas as pd

def execute(parent_path, output_path, margin):

    """
    This code aims to remove all the non necessary data before the real tasks start as sometimes the recording is started before perfect signal quality (in order to avoid forgetting to press the record button)

    Args:
        parent_path (str): Path indicated by user in the GUI that containts the original data
        output_path (str): Path indicated by user in the GUI where the new data will be stored
        margin (int): Number of samples to sustract to the trimmed data

    Returns:
        None
    """

    """
    Trim early/late parts of raw EEG recordings and save a working copy.
    It creates a working copy of a raw session folder and trims the continuous
    EEG (`EEG.csv`) so only the samples corresponding to the recorded tasks
    remain (with an adjustable margin of samples on each side).

    Args:
        parent_path (str): Path to the original session folder. The folder
                        will be copied into output_path.
        output_path (str): Path to create a working copy where trimmed files
                        will be written (created if needed).
        margin (int): Number of samples to extend the trimmed region beyond
                    the detected start and end indices (applied as subtract
                    from start and add to end).

    Returns:
        None. Primary effects are a copied folder and
        an overwritten `EEG.csv` with trimmed samples.

    Algorithm / behavior:
        - Normalize provided paths and assert  exists; exit if not.
        - Copy entire  into  using .
        - Locate the first subfolder matching 'BBT-E32*' and read:
            * UTC.csv (must contain 'utc_timestamp' and 'steady_timestamp')
            * EEG.csv  (must contain 'steady_timestamp')
            * Markers/Tasks-Completed.csv (must contain 'Timestamp_start' and 'Timestamp_end')
        - Convert relevant timestamp columns to numeric.
        - Find the UTC row nearest to the Task-0 `Timestamp_start` and use its
        `steady_timestamp` as trimming start. Convert that steady timestamp to
        an index in EEG.csv, subtract the margin.
        - Find the UTC row nearest to the final task `Timestamp_end` and use its
        `steady_timestamp` as trimming end. Convert to an index in EEG.csv, and add the margin.
        - Slice `EEG.csv` rows between these indices and overwrite `EEG.csv` in the working copy.

    Notes and edge-cases:
        - This routine assumes one row per recorded sample in `EEG.csv`
    """

    #Obtains the input and output paths from the GUI (input path = orginila data, output_path = copy of the original data, but we will overwrite info)
    parent_path = os.path.normpath(parent_path) #converts the string without spaces in a path-like format 
    output_path = os.path.normpath(output_path)

    #Checks if the indicated input folder exists
    if not os.path.exists(parent_path):
        print(f"Path '{parent_path}' does not exist")
        quit()

    #Clone all info to avoid using the original data
    shutil.copytree(parent_path,output_path,dirs_exist_ok=True)

    #Extract steady timestamp (read README for timestamp information) for start Task-0
    subfolders_path = glob.glob(os.path.join(output_path, "BBT-E32*"))
    subfolder_path = subfolders_path[0] #actual subfolder path with the data


    #obtain the UTC.csv, signal and Tasks-Completed.csv path (the last one is, in fact, the same for all the signals)
    UTC_path = os.path.join(subfolder_path, 'UTC.csv')
    signal_path = os.path.join(subfolder_path, "EEG.csv")
    tasks_path = os.path.join(output_path, 'Markers', 'Tasks-Completed.csv')

    # Loading data into pandas DataFrames
    tasks_df = pd.read_csv(tasks_path, sep=',')
    utc_df = pd.read_csv(UTC_path, sep=',')
    signal_df = pd.read_csv(signal_path, sep=',')

    tasks_df["Timestamp_start"] = pd.to_numeric(tasks_df["Timestamp_start"], errors="coerce")
    tasks_df["Timestamp_end"] = pd.to_numeric(tasks_df["Timestamp_end"], errors="coerce")
    utc_df["utc_timestamp"] = pd.to_numeric(utc_df["utc_timestamp"], errors="coerce")

    #Getting the index of the utc_timestamp in UTC.csv closer to our Timestamp_start for Task-0
    idx_start = utc_df["utc_timestamp"].sub(tasks_df["Timestamp_start"].iloc[0]*1000000).abs().idxmin()
    #Multiplying by 10^6 because we are using different resolutions. That means, the UTC of the device is 16 digit length, while markers are 10 digit lenght
    #Getting the actual steady_timestamp value
    steady_start = utc_df.loc[idx_start, "steady_timestamp"]

    #Getting the index associated to that steady_start in order to substract the margin
    idx_start = signal_df[signal_df["steady_timestamp"]==steady_start].index[0]
    idx_start = max(0, idx_start-margin)

    #Getting the index of the utc_timestamp in UTC.csv closer to our Timestamp_end for last Task
    # Tasks-Completed is filled row by row, so the last row equals the last task
    idx_end = utc_df["utc_timestamp"].sub(tasks_df["Timestamp_end"].iloc[-1]*1000000).abs()
        #For the steady_end, we need the index of the last one with minimun difference between steady_timestamp and steady_end
    #if we were not to use a margin (as in extract tasks or rounds) the other method works well as it is comparing values, not taking the index
    idx_end = idx_end[idx_end == idx_end.min()].index[-1]
    #Multiplying by 10^6 because we are using different resolutions. That means, the UTC of the device is 16 digit length, while markers are 10 digit lenght
    #Getting the actual steady_timestamp value
    steady_end = utc_df.loc[idx_end, "steady_timestamp"]
    
    #Substract the index associated to that steady_end in order to add a margin
    idx_end = signal_df[signal_df["steady_timestamp"]==steady_end].index[0]
    idx_end = min(len(signal_df)-1,idx_end+margin)
    

    #Trim the signal
    filtered_signal_df = pd.DataFrame()
    #mask = (signal_df["steady_timestamp"] >= steady_start) & (signal_df["steady_timestamp"] <= steady_end)
    mask = (signal_df.index >= idx_start) & (signal_df.index <= idx_end)
    filtered_signal_df = pd.concat([filtered_signal_df, signal_df[mask]])

    # Saving the new file with filtered data
    filtered_signal_df.to_csv(signal_path, sep=',', index=False)
    print(f'Avoiding early start completed. File saved in: {signal_path}')

