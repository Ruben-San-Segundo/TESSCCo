"""
This script will change the markers in CSV into a mode that EEGLab can understand for epoching. 
This is, for each marker, the time in microseconds when a marker occurred since the recording started.
This script also deletes repetitions of the same marker inmediatly after each other, keeping the last one (this can happen if a subject speaks multiple times in a row or if they say a different word).
"""


#Import libraries used
import os
import pandas as pd
import config
import shutil

def execute(parent_path,subfolder_path):
    '''
    This script will change the markers in CSV into a mode that EEGLab can understand for epoching. 
    This is, for each marker, the time in microseconds when a marker occurred since the recording started.
    Args:
        parent_path (str): Path to the  trimmed and translated data
        subfolder_path (str): Path to the BBT-E32*
    
    Returns:
        epoch_path (str): Path to the EEGLab epoch file generated
    '''

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
                    case "Task-1" | "Task-3":
                        latency.append(row["steady_go"]-recording_start)
                        type.append(config.markers_words_os.get(row["Word"]))
                        position.append(row["Round"])
                    case "Task-2" | "Task-4":
                        latency.append(row["steady_go"]-recording_start)
                        type.append(config.markers_words_cs.get(row["Word"]))
                        position.append(row["Round"])

    #save the DataFrame to be exported
    epoch_df = pd.DataFrame()
    epoch_df["latency"] = latency
    epoch_df["type"] = type
    epoch_df["position"] = position

    #Order the dataFrame by latency. inplace so the epoch_df overwrites
    epoch_df.sort_values(by="latency", ascending=True,inplace=True)

    #Export the eeglab_epoch_file
    epoch_path = os.path.join(parent_path,"epoch_eeglab.txt")
    epoch_df.to_csv(epoch_path, sep='\t', index=False, header=True)
    print("EEGLab epoch file saved in: ", epoch_path)

    return epoch_path

def delete_repetitions(filepath):
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