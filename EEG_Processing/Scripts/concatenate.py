"""
Concatenate.py provides utilities to concatenate per-session cleaned EEG epochs and their associated label files into single dataset-level files for downstream
analysis. 

Typical workflow:
    - After manual cleaning and label extraction (per-session),
    run concatenate_epochs to build a single .mat file containing
    all epochs in shape (trials x timepoints x channels).
    - Run concatenate_labels to build a single CSV containing all per-epoch
    metadata in the same order as the concatenated epochs.

    
Key behaviors:
    - Reads per-session Clean_epochs.mat (expects dataset variable 'EEGdata')
    transposes axes to ordering before concatenation.
    - Reads per-session Clean_labels.csv with pandas and concatenates rows.
    - Skips subject/session combinations listed in the skip collection.


Inputs (function-level):
    - in_out_root (str): Root folder containing Subject_XX/Session_YY subfolders.
    - n_subjects (int): Number of subjects to process (1..n_subjects).
    - n_sessions (int): Number of sessions per subject (1..n_sessions).
    - skip (iterable of 2-element containers): Sets/tuples indicating
    subject/session pairs to skip, e.g. { "Subject_21", "Session_02" }.

    
Outputs:
    - Clean_concatenated_epochs.mat : MATLAB .mat file with key "epochs" (numpy
    array saved with scipy.io.savemat), shape (total_trials, timepoints, channels).
    - Clean_concatenated_labels.csv : CSV file with concatenated per-epoch
    metadata (same order as concatenated epochs).
    - Console messages describing load/save progress.

    
Dependencies:
    - Python: h5py, scipy, numpy, pandas, extract_labels (local module)
    - The per-session files must exist:
        * Clean_epochs.mat (MATLAB -v7.3 HDF5 format, variable "EEGdata")
        * Clean_labels.csv (CSV with headers)
    - Note: h5py reads MATLAB -v7.3 files; the code corrects axis order by transposing.

    
Important implementation notes:
    - The script loads "EEGdata" and transpose order axes: to (epochs, timepoints, channels) before concatenation.
    - Ensure sufficient memory to hold the concatenated array; 

    
Author:
Mario Lobo (UPM)
mario.lobo.alonso@alumnos.upm.es
Version:
27-10-2025
"""



import os
import h5py
from scipy import io
import numpy as np
import pandas as pd
import extract_labels


def concatenate_epochs(in_out_root, n_subjects, n_sessions, skip):
    """
    Concatenate per-session epoch MAT files into a single .mat file.
    Args:
        in_out_root (str): Root folder path containing Subject_XX/Session_YY folders.
        n_subjects (int): Number of subjects to process (subjects numbered 1..n_subjects).
        n_sessions (int): Number of sessions per subject (sessions numbered 1..n_sessions).
        skip (iterable): Collection of subject/session identifiers to skip. Each
            entry should be a 2-element container (e.g., a set or tuple)
            containing the subject folder name and the session folder name,
            for example: {"Subject_21", "Session_02"}.

    Returns:
        None

    Outputs:
        - Saves `Clean_concatenated_epochs.mat` to [in_out_root] containing
        the key "epochs" with shape (total_trials, timepoints, channels).

    Notes:
        - The function expects `Clean_epochs.mat` to contain the variable
        "EEGdata" stored in MATLAB's -v7.3 HDF5 format. h5py reads the
        dataset with axes in Fortran/C order differences; the function
        transposes axes to produce the (epochs, timepoints, channels) order.
        - Large concatenations may require substantial RAM. 
    """

    # Initialize arrays for data storage
    all_epochs = []

    # Saving the data of each session of each subject
    for i in range(1,n_subjects+1):
        subject = f'Subject_{i:02d}'

        for session in range(1, n_sessions+1):
            # Obtaining the path
            session_name = f'Session_{session:02d}'
            if {subject, session_name} in skip:
                print(f"Skipping {subject} {session_name}. See documentation for issues.")
                continue
            session_in_path = os.path.join(in_out_root, subject, session_name)     

            # Extracting the data from matlab format files
            mat_path = os.path.join(session_in_path,"Clean_epochs.mat")
            print(f"Loading: {mat_path}")

            with h5py.File(mat_path, "r") as f:
                    # h5py devuelve un dataset en orden inverso de ejes (Fortran vs C)
                    # Por eso lo transponemos luego
                    epochs = np.array(f["EEGdata"]).T
            
            epochs_transpossed = np.transpose(epochs, (2, 1, 0))
            all_epochs.append(epochs_transpossed)


    # Saving the concatenated data
    concatenated_epochs = np.concatenate(all_epochs,axis=0)
    print(f"Concatenated {len(all_epochs)} files.")
    print(f"Final shape of concatenated array: {concatenated_epochs.shape}")

    mat_out = os.path.join(in_out_root,"Clean_concatenated_epochs.mat")
    io.savemat(mat_out, {"epochs": concatenated_epochs})



def concatenate_labels(in_out_root, n_subjects, n_sessions, skip):
    """
    Concatenate per-session label CSVs into a single CSV.

    Args:
        in_out_root (str): Root folder path containing Subject_XX/Session_YY folders.
        n_subjects (int): Number of subjects to process (1..n_subjects).
        n_sessions (int): Number of sessions per subject (1..n_sessions).
        skip (iterable): Collection of subject/session identifiers to skip (same format as in concatenate_epochs).

    Returns:
        None

    Outputs:
        - Saves `Clean_concatenated_labels.csv` to in_out_root containing the
        concatenated label rows from all processed sessions in the same order
        as `Clean_concatenated_epochs.mat`.

    Notes:
        - Ensure the per-session `Clean_labels.csv` files share a consistent header and data types.        
    """

    all_labels = []

    for i in range(1,n_subjects+1):
        subject = f'Subject_{i:02d}'


        for session in range(1, n_sessions+1):
            # Obtaining the path
            session_name = f'Session_{session:02d}'
            if {subject, session_name} in skip:
                print(f"Skipping {subject} {session_name}. See documentation for issues.")
                continue
            session_in_path = os.path.join(in_out_root, subject, session_name)     

            labels_path= os.path.join(session_in_path,"Clean_labels.csv")
            print(labels_path)

            # Grouping the labels
            labels = pd.read_csv(labels_path, header=0, sep=",")
            all_labels.append(labels)

    # Saving the concat labels        
    labels_concat = pd.concat(all_labels, axis=0, ignore_index=True)
    print(f"Se concatenaron {len(labels_concat)} archivos.")
    print(f"Forma final del array concatenado: {labels_concat.shape}")

    csv_out = os.path.join(in_out_root, "Clean_concatenated_labels.csv")
    labels_concat.to_csv(csv_out, index=False)

if __name__ == "__main__":
    # Example usage
    pre_processed_root = "C:/Users/user/Desktop/Mario Lobo/Silent Speech Data Amazon Non-Native/3. Pre-processed"
    n_subjects = 3
    n_sessions = 2

    not_process_subjects_and_sessions = [{"Subject_03", "Session_02"}] #List of subjects that will not be processed (for example, if they have corrupted data)

    
    #Go across all the subjects for the label extraction(step 3) 
    for i in range(1,n_subjects+1):
        subject = f'Subject_{i:02d}'

        #Go across all the sessions for each subject
        for session in range(1, n_sessions+1):

            session_name = f'Session_{session:02d}'
            if {subject, session_name} in not_process_subjects_and_sessions:
                print(f"Skipping {subject} {session_name}. See documentation for issues.")
                continue

            correct_labels_in_path = os.path.join(pre_processed_root, subject, session_name, 'Clean_labels.csv')

            extract_labels.english_vs_spanish(correct_labels_in_path)
            extract_labels.covert_vs_overt(correct_labels_in_path)
            extract_labels.just_words(correct_labels_in_path)


    #finally, the concatenation of .mat epochs files and .mat label files is made (think how to make different concatenations (for example LOSO))
    concatenate_epochs(pre_processed_root, n_subjects, n_sessions, not_process_subjects_and_sessions)
    concatenate_labels(pre_processed_root, n_subjects, n_sessions, not_process_subjects_and_sessions)

