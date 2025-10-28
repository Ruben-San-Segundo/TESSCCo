"""
eeglab_epoch_file_generator.py converts experiment marker CSVs into an EEGLAB-compatible epoch file and
removes immediate repeated markers. The module produces a tab-separated
epoch_eeglab.txt that lists, for each event, the latency (microseconds
since recording start), the event type id, the event position (round),
and the session index. It also provides a utility to remove consecutive
duplicate markers (keeping the last occurrence) and creates a backup.

High-level steps performed by execute:
    1. Read the session EEG.csv to determine the recording start timestamp
    (column steady_timestamp).
    2. Iterate through configured task marker files (Task-0..Task-N) located
    under <parent_path>/Markers/Markers-Task-X.csv.
    3. For each marker row, compute latency = (marker_steady_time - recording_start)
    and map Word IDs to EEGLAB eventType using mappings defined in
    the project's config.py (e.g., markers_words_os, markers_words_cs, markers_calibration).
    4. Aggregate [latency, type, position, session] entries, sort by latency,
    and save to epoch_eeglab.txt (tab-separated) in parent_path.
    5. Use delete_repetitions to optionally clean repeated consecutive events


Inputs / assumptions:
    - parent_path (str): Path to the trimmed & translated session folder
    (project expects a Markers subfolder containing Markers-Task-*.csv).
    - subfolder_path (str): Path to the session folder that contains EEG.csv.
    - session (int): Numeric session index to include in the exported file. 
    Usually, this is passed through a loop from Batch_processing.py
    - Marker CSVs must include columns named Word, Round, and either
    steady_start (Task-0) or steady_go (other tasks). Missing numeric
    data in these columns is coerced to NaN and skipped accordingly.
    - Mappings from Word -> event id are provided in config.py as dictionaries:
    markers_calibration, markers_words_os, markers_words_cs.
    - The script assumes config.number_tasks indicates how many tasks to read
    (it iterates from 0 to number_tasks inclusive).

Outputs:
    - epoch_eeglab.txt saved in parent_path
    - delete_repetitions(filepath) will create a backup (filename with -deprecated)
    if it removes lines, and overwrite the original file with the cleaned version.


Author:
Mario Lobo (UPM)
mario.lobo.alonso@alumnos.upm.es
Version:
28-10-2025
"""



#Import libraries used
import os
import pandas as pd
import config
import shutil

def execute(parent_path,subfolder_path, session):
    """
    Generate an EEGLAB-compatible epoch event file from marker CSVs. This is a tab-separated epoch.txt file
    with columns: latency (time since recording started), event type id, position (round), and session index.

    Args:
        parent_path (str): Root path for the trimmed & translated dataset for a subject.
                        The function expects marker files at:
                        os.path.join(parent_path, "Markers", "Markers-Task-<i>.csv").
        subfolder_path (str): Path to the session folder that contains `EEG.csv`.
        session (int): Session index to write into the epoch file [session] column.

    Returns:
        epoch_path (str): Full path to the generated epoch file (epoch_eeglab.txt).

    Behavior:
        - Loads `EEG.csv` from the subfolder_path and reads `steady_timestamp` to
        determine recording start time.
        - Iterates tasks i = 0..config.number_tasks, reads `Markers-Task-i.csv`,
        coerces time columns (`steady_start` or `steady_go`) to numeric, and
        for valid rows computes latency = marker_time - recording_start.
        - Maps marker Word IDs to EEGLAB event type IDs using dictionaries in config.py:
            * Task-0 -> config.markers_calibration
            * Task-1, Task-3 -> config.markers_words_os
            * Task-2, Task-4 -> config.markers_words_cs
        - Aggregates entries, sorts by latency ascending, writes `epoch_eeglab.txt`
        to parent_path as a tab-separated file with header, and returns the path.

    Notes:
        - Rows where Word == -1 or Round == 0 are skipped (calibration/round markers).
        - Ensure config.py contains the required mappings and number_tasks.
        - The produced latency values must be compatible with the time unit expected
        by the EEGLAB import (e.g., if EEGLAB is called with `timeunit=1e-06`,
        latencies must be in microseconds).
    """


    #Path to all the data (complete recordings and separated Tasks)
    parent_path = os.path.normpath(parent_path)
    subfolder_path = os.path.normpath(subfolder_path)

    #Extract the very first steady timestamp from the EEG (Note: EEG already trimmed if pipeline from Trial Separation followed)
    EEG_path = os.path.join(subfolder_path,"EEG.csv")
    eeg_df = pd.read_csv(EEG_path, sep=',')
    recording_start = eeg_df["steady_timestamp"].iloc[0]

    #Variables for generating a new DataFrame to export
    latency = []
    type = []
    position = []
    sessions = []

    #For every task (Note that in FESSCCo the calibration is considered as Task-0)
    for i in range(config.number_tasks+1):
        #Obtain names, paths and DataFrames
        task = "Task-"+str(i)
        marker = "Markers-"+task+".csv"
        task_path = os.path.join(parent_path, "Markers", marker)
        task_df = pd.read_csv(task_path)

        #WARNING: This is for FESSCCo as the experimentation was developped that way. In other projects probably it should be an other for loop just for calibrations
        if task =="Task-0":
            task_df["steady_start"] = pd.to_numeric(task_df["steady_start"], errors="coerce")
        else:
            task_df["steady_go"] = pd.to_numeric(task_df["steady_go"], errors="coerce")

        #All the markers are stored sequentially in a csv file row by row.
        for _, row in task_df.iterrows():
            #The beggining and end of a roun is marked with a Word = -1. A little calibration for each Task is considered as Round 0, Word 0 (it can be added to the dictionarys in config.py)
            if row["Word"] == -1 or row["Round"] == 0:
                continue
            else:
                #In FESSCCo there are 3 main tasks that shares marker in the experimentation. We could consider all the words without distinguish cover or overt just using one dictionary and without switch case statement
                #It depends on the needs
                match task:
                    case "Task-0":
                        latency.append(row["steady_start"]-recording_start)
                        type.append(config.markers_calibration.get(row["Word"]))
                        position.append(row["Round"])
                        sessions.append(session)
                    case "Task-1" | "Task-3":
                        latency.append(row["steady_go"]-recording_start)
                        type.append(config.markers_words_os.get(row["Word"]))
                        position.append(row["Round"])
                        sessions.append(session)
                    case "Task-2" | "Task-4":
                        latency.append(row["steady_go"]-recording_start)
                        type.append(config.markers_words_cs.get(row["Word"]))
                        position.append(row["Round"])
                        sessions.append(session)

    #save the DataFrame to be exported
    epoch_df = pd.DataFrame()
    epoch_df["latency"] = latency
    epoch_df["type"] = type
    epoch_df["position"] = position
    epoch_df["session"] = sessions

    #Order the dataFrame by latency. inplace so the epoch_df overwrites
    epoch_df.sort_values(by="latency", ascending=True,inplace=True)

    #Export the eeglab_epoch_file
    epoch_path = os.path.join(parent_path,"epoch_eeglab.txt")
    epoch_df.to_csv(epoch_path, sep='\t', index=False, header=True)
    print("EEGLab epoch file saved in: ", epoch_path)

    return epoch_path

def delete_repetitions(filepath):
    """
    Remove consecutive duplicate events from an EEGLAB epoch/event file.
    When a subject produces repeated immediate markers because of an error during the task (same type and position),
    we keep only the last occurrence and remove earlier consecutive duplicates. This helps avoid duplicate epoch creation in EEGLAB.

    Args:
        filepath (str): Path to the epoch/event file to clean (CSV). The function reads the file into a pandas DataFrame,
                        assuming columns at least 'type' and 'position'.

    Returns:
        None

    Behavior:
        - Reads the file.
        - Builds a mask that keeps a row if either the 'type' differs from the next
        row OR the 'position' differs from the next row. This effectively removes
        a run of identical (type, position) entries, preserving the last of them.
        - If any rows are removed, creates a backup of the original file with
        suffix `-deprecated` before overwriting the original file with the
        cleaned version.

    Notes:
        - The function compares each row to the next row (uses shift(-1)). It will
        not remove non-consecutive duplicates (only immediate repeats).
        - Validate that the file encoding and column names match expectations.
    """
    # Read original file
    df = pd.read_csv(filepath, sep=r'\s+|,', engine='python')
    n_original = len(df)

    # Delete consecutive duplicates, keeping the last occurrence
    mask = (df['type'] != df['type'].shift(-1)) | (df['position'] != df['position'].shift(-1))
    df_clean = df[mask].copy()
    n_clean = len(df_clean)

    # Verify if any duplicates were removed
    if n_clean < n_original:
        # Create backup copy
        base, ext = os.path.splitext(filepath)
        backup_path = f"{base}-deprecated{ext}"
        shutil.copy2(filepath, backup_path)
        print(f"Backup copy created: {backup_path}")

        # Save cleaned file
        df_clean.to_csv(filepath, index=False)
        print(f"Cleaned file saved as: {filepath}")
        print(f"Reduced from {n_original} to {n_clean} lines.")
    else:
        print("No consecutive duplicates detected. No changes made and no copy created.")