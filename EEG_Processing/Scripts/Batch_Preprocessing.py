"""
Batch_Preprocessing.py orchestrates the full, preprocessing pipeline for a subset of BitBrain EEG recordings. The script:
    - Runs trimming and timestamp translation per subject/session (calls trim_and_translate.execute).
    - Starts the MATLAB Engine and calls the EEGLAB-based batch_Preprocessing.m MATLAB script to perform filtering, epoching,
    ICA and export of per-session preprocessed outputs.
    - Prints completion status and points to the manual follow-up steps
    (visual epoch selection and label concatenation).

Usage:
    - Run from a Python environment with the MATLAB Engine for Python installed and configured.
    - Edit the configuration variables near the top of the file to point to your dataset root paths, channel location file and desired subject/session
    range, then run: python Batch_Preprocessing.py
    - After MATLAB preprocessing finishes, run interactive epoch selection
    (Batch_epoch_selection.m via MATLAB) and then run concatenate.py to build final analysis-ready data matrices.

Inputs (top-of-file variables / required files):
    - raw_root (str): path to raw BitBrain CSV recordings (example: "C:/.../1. RAW")
    - trimmed_and_translated_root (str): output folder for trimmed / translated sessions (example: "C:/.../2. Trimmed and Translated")
    - pre_processed_root (str): folder where MATLAB/EEGLAB outputs will be saved (example: "C:/.../3. Pre-processed")
    - loc_path (str): path to channel locations file used by EEGLAB (e.g."BitBrain_SSI_placement.loc")
    - n_subjects (int): number of subjects to process (script loops 1..n_subjects)
    - n_sessions (int): number of sessions per subject (script loops 1..n_sessions)
    - margin_trim (int): margin (in samples) passed to trimming routine
    - not_process_subjects_and_sessions (iterable of pairs): set-like entries identifying subject/session combinations to skip; entries should be in
    the form {"Subject_XX", "Session_YY"} (the script checks membership with {subject, session_name} in this collection).

Outputs / Side effects:
    - Trimmed/translated session folders and files under trimmed_and_translated_root (produced by trim_and_translate.execute).
    - Preprocessed EEGLAB outputs under pre_processed_root produced by the MATLAB Batch_Preprocessing script (e.g., Complete.set, EEG.csv, Complete_epoched.set, Correct_epochs.set, Correct_epochs.mat, Correct_labels.csv for each session).
    - The script starts a MATLAB Engine process (matlab.engine), adds the Python script folder to MATLAB path and runs the MATLAB Batch_Preprocessing function (so MATLAB/EEGLAB must be available).


Dependencies:
    - Python:
        * MATLAB Engine API for Python (matlab.engine)
        * trim_and_translate module (local)
        * Python standard library: os, time
    - MATLAB:
        * EEGLAB and required plugins (ICLabel, clean_rawdata)
        * Batch_Preprocessing.m in the same folder or on MATLAB path
    - File system:
    * The directory structure and file naming conventions used by the trimming/translation step and the MATLAB preprocessing scripts must be consistent (Subject_XX/Session_YY/...).

Notes:

    - Partial failure mid-run requires manual handling: some intermediate outputs may need recalculation if a
    later stage fails. 
    - The script pauses briefly before launching MATLAB to ensure OS handles file locks from the trimming step are released (time.sleep(5)).
    - The MATLAB call places variables into the MATLAB workspace so Batch_Preprocessing.m can access them


Author:
Mario Lobo (UPM)
mario.lobo.alonso@alumnos.upm.es
Version:
27-10-2025
"""


import trim_and_translate
import os
import matlab.engine as mtlb
import time


raw_root = "C:/Users/user/Desktop/Mario Lobo/Silent Speech Data Amazon Non-Native/1. RAW"
trimmed_and_translated_root = "C:/Users/user/Desktop/Mario Lobo/Silent Speech Data Amazon Non-Native/2. Trimmed and Translated"
pre_processed_root = "C:/Users/user/Desktop/Mario Lobo/Silent Speech Data Amazon Non-Native/3. Pre-processed"
# Path to the location file (it is usually the same for every subject)
loc_path = "C:/Users/user/Desktop/AMAZON_BCI/Code/Amazon_SSI/EEG_Processing/Scripts/BitBrain_SSI_placement.loc"

n_subjects = 3
n_sessions = 2

margin_trim = 512 #margin in samples for the trimming

#not_process_subjects_and_sessions = [{"Subject_11", "Session_02"},{"Subject_21", "Session_02"}] #List of subjects that will not be processed (for example, if they have corrupted data)
not_process_subjects_and_sessions = [{"Subject_03", "Session_02"}] #List of subjects that will not be processed (for example, if they have corrupted data)

# Go across all the subjects for the trim and translation (step 1) 
for i in range(1,n_subjects+1):
    subject = f'Subject_{i:02d}'

    #Go across all the sessions for each subject
    for session in range(1, n_sessions+1):
        session_name = f'Session_{session:02d}'

        if {subject, session_name} in not_process_subjects_and_sessions:
            print(f"Skipping {subject} {session_name}. See documentation for issues.")
            continue
        session_in_path = os.path.join(raw_root, subject, session_name)
        session_out_path = os.path.join(trimmed_and_translated_root, subject, session_name)

        trim_and_translate.execute(session_in_path,session_out_path,margin_trim,session)

#little delay to ensure everything has closed correctly and the MATLAB process can start
time.sleep(5)

#############Once the trimming and translation is completed for all the session of all subjects, we continue with the MATLAB processing###########
#Start matlab engine
eng = mtlb.start_matlab()
#Define the working directory
script_dir = os.path.dirname(os.path.abspath(__file__))
eng.addpath(script_dir, nargout=0)
#Execute the Batch_Processing EEG
#Prepare the variables for Batch_processing
eng.workspace['root_dir'] = trimmed_and_translated_root
eng.workspace['out_dir'] = pre_processed_root
eng.workspace['loc_path'] = loc_path
eng.workspace['n_subjects'] = n_subjects
eng.workspace['n_sessions'] = n_sessions
eng.Batch_Preprocessing(nargout=0)

#Once everything is MATLAB processed, we do a manually selection of epochs with Batch_Epoch_Selection script
#After that, we continue with the label extraction and concatenation in concatenate.py

print("ALL THE PRE-PROCESSING HAS ENDED. Now, run Batch_epoch_Selection.m in MATLAB to manually select epochs, and then run concatenate.py to build final data matrices.")
        

