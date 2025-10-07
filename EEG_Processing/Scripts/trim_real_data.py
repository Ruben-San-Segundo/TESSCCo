'''
This code makes the intial steps of the pre-processing pipeline presented in the README.
Version 0.1
WARNING!!! Even if the code is intented to be scalable and usable for different projects, the main focus was on "FESSCCo" project.
Further addaptations might have to be done by users working in different projects.

Brief explanation of the code:
    - Takes the input and output path from the GUI
    - Clones the original data into the output path (avoiding data loses if something goes wrong)
    - Merges the ExG data and splits the IMU data. Marked with a WARNING!!! as this is specific for BitBrain devices
    - Trims all the data before the start of the Task-0 minus the margin (in samples)
'''
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

