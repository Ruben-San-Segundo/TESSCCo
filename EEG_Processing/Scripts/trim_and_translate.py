"""
This file contains the first part of the preparation of signals for AI use.
It uses modules from the SDK repository, but  the folder "EEG_PRocessing" contains specifically what is needed for EEG preparation.
That means, trimming the beginning and ending of the recordings, timestamp translation, generation of EEGLab epoch files, a complete MATLAB pre-processing
and concatenation of epochs
"""

#Import needed modules

import eeglab_epoch_file_generator
import extract_steady_timestamps
import sort_tasks
import trim_real_data
import os
import glob
import config
import extract_labels

#main function for executing the first steps of pre-processing for just one subject
def execute(raw_path : str, trimmed_and_translated_path : str, margin : int) -> None:
    """
    This function contains the first execution steps to convert a RAW data EEG recording into a matrix of epochs that allows to feed a DL algorithm.
    Specifically, this function trims the data, translates the marker files and extracts the EEGLab epoch file needed for epoching.
    
    Args:
        raw_path (str): Path to the folder with the complete data of one subject (e.g. RAW/Subject_XX/Session_XX).
        trimmed_and_translated_path (str): Path to the folder where translated markers file with task information and trimmed EEG will be stored (e.g. Trimmed/Subject_XX/Session_XX)
        pre_processed_path (str): Path where all the pre_processed data, labels and tensors will be stored (e.g. Pre-processed/Subject_XX/Session_XX)
        margin (int): Number of samples extra to save while trimming 

    Returns:
        None
    """

    ###########Trim the beginning and ending of the subjects' session EEG.csv###########
    trim_real_data.execute(raw_path,trimmed_and_translated_path,margin)
    print("\n\n\n!!!Trim completed!!!")

    ###########Sorting the completed tasks by name rather than by timestamps. That allows a correct code execution###########
    tasks_completed_path = os.path.join(trimmed_and_translated_path,"Markers","Tasks-Completed.csv") #Path to the not sorted tasks
    sort_tasks.sort_tasks(tasks_completed_path, tasks_completed_path)
    print("\n\n\n!!!Order Tasks-Completed.csv completed!!!")

    ###########Extract the steady timestamps for the Tasks-completed.csv file###########
    #Obtaining the correct folder with the EEG data for the subjects' session
    subfolders_path = glob.glob(os.path.join(trimmed_and_translated_path, "BBT-E32*"))
    subfolder_path = subfolders_path[0] #actual subfolder path with the data
    utc_path = os.path.join(subfolder_path, "UTC.csv")

    #Extract the timestamps
    extract_steady_timestamps.extract_steady_timestamps(tasks_file=tasks_completed_path,utc_file=utc_path,output_file=tasks_completed_path,tasks=False)
    print("\n\n\n!!!Translate Tasks-Completed.csv completed!!!")


    ###########Extract the steady timestamps for the different tasks files###########
    for i in range(config.number_tasks+1):
        #Obtaining the path for each task
        tarea = "Markers-Task-" + str(i) + ".csv"
        tarea_path = os.path.join(trimmed_and_translated_path, "Markers",tarea)
        #Actual timestamp extraction
        extract_steady_timestamps.extract_steady_timestamps(tarea_path,utc_path,tarea_path,True)

    ###########Generating the files EEGLab needs for epoching###########
    epoch_path = eeglab_epoch_file_generator.execute(trimmed_and_translated_path,subfolder_path)

    eeglab_epoch_file_generator.delete_repetitions(epoch_path)

if __name__ == "__main__":
    #execute the code with some standard variables
    input_path_user = "Path/to/the/folder/with/all/the/data/correctly/ordered"
    output_path_user = "Path/to/the/folder/where/all"