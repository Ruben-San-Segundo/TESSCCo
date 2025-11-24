"""
trim_and_translate.py orchestrates the initial pre-processing steps for a single subject/session:
      - Trim raw session recordings (avoid early/late poor-quality segments)
      - Sort and translate marker CSVs to device steady timestamps
      - Generate an EEGLAB-compatible epoch file and remove immediate repeated markers

      This script is a lightweight driver that calls the helper modules:
`trim_real_data`, `sort_tasks`, `extract_steady_timestamps`, and
`eeglab_epoch_file_generator`. It does not implement those transformations
itself — it sequences them for one subject/session.

Effects:
    - Trimmed EEG.csv and translated marker CSVs saved under `trimmed_and_translated_path`
    - An EEGLAB epoch file (`epoch_eeglab.txt`) in `trimmed_and_translated_path`
    - Console prints indicating progress for each step
    - Note: this script modifies files on disk (overwrites sorted/translated marker CSVs)

Author:
    Mario Lobo (UPM)
    mario.lobo.alonso@alumnos.upm.es
Version:
    12-11-2025
"""

#Import needed modules

import eeglab_epoch_file_generator
import extract_steady_timestamps
import sort_tasks
import trim_real_data
import os
import glob
import config

#main function for executing the first steps of pre-processing for just one subject
def execute(raw_path : str, trimmed_and_translated_path : str, margin : int, session : int) -> None:
    """
    Orchestrates trimming and marker translation for one subject/session.

    High-level steps (performed in order):
      1. Create a working copy and trim the EEG recording to task window
         (calls `trim_real_data.execute`).
      2. Sort the Tasks-Completed marker file in-place (calls `sort_tasks.sort_tasks`).
      3. Map marker UTC timestamps to device steady timestamps for the
         Tasks-Completed file (calls `extract_steady_timestamps`).
      4. Process each Task-X marker file similarly (Task-0..Task-N).
      5. Generate the EEGLAB epoch file and remove immediate duplicate markers
         (calls `eeglab_epoch_file_generator.execute` and `.delete_repetitions`).

    Args:
        raw_path (str): Path to the original raw session folder (e.g. RAW/Subject_01/Session_01).
        trimmed_and_translated_path (str): Destination working folder for trimmed EEG and translated markers.
        margin (int): Number of extra samples to include when trimming (applied around start/end).
        session (int): Session index passed to the epoch-file generator (used in the 'session' column).

    Returns:
        None

    Side-effects / outputs:
      - Copies and trims files under `trimmed_and_translated_path` (overwrites sorted/translated CSVs).
      - Writes `epoch_eeglab.txt` into `trimmed_and_translated_path`.
      - Prints progress messages to stdout.

    Important assumptions & notes:
      - Expects BitBrain-style folder/file layout (EEG.csv, UTC.csv, Markers/Tasks-Completed.csv, Markers-Task-*.csv).
      - Relies on `config.number_tasks` to determine how many Task-*.csv files to process.
      - Helper functions perform file writes and may overwrite existing files; keep backups if needed.
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
    epoch_path = eeglab_epoch_file_generator.execute(trimmed_and_translated_path,subfolder_path, session)

    eeglab_epoch_file_generator.delete_repetitions(epoch_path)

if __name__ == "__main__":
    #execute the code with some standard variables
    input_path_user = "Path/to/the/folder/with/all/the/data/correctly/ordered"
    output_path_user = "Path/to/the/folder/where/all"