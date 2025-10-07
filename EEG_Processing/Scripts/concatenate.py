"""
This script contains functions to concatenate data and labels.
Specifically, if we want the data of all the subjects in just one matrix and the labels in an other file with the same order.
"""

import os
import scipy.io
import numpy as np
import pandas as pd
import csv


def concatenate_epochs(in_out_root, n_subjects, n_sessions):

    '''
    This script will put all the epochs in just one .mat file
    Args:
        in_out_root (str): Path to all the data (in_out_root/Subject_XX/Session_XX/Data)
        n_subjects (int): Number of subjects data to concatenate
        n_sessions (int): Number of sessions of each subject to concatenate
    
    Returns:
        None
    '''

    # Initialize arrays for data storage
    all_epochs = []
    metadata = []

    # Saving the data of each session of each subject
    for i in range(1,n_subjects+1):
        subject = f'Subject_{i:02d}'

        for session in range(1, n_sessions+1):
            # Obtaining the path
            session_name = f'Session_{session:02d}'
            session_in_path = os.path.join(in_out_root, subject, session_name)     

            # Extracting the data from matlab format files
            mat_path = os.path.join(session_in_path,"epochs.mat")
            print(f"Loading: {mat_path}")

            datos = scipy.io.loadmat(mat_path)
            epochs = datos['epochs']
            epochs_transpossed = np.transpose(epochs, (2, 1, 0))
            all_epochs.append(epochs_transpossed)

            # Creating some metadata
            n_epochs = epochs_transpossed.shape[0]
            for e in range(1,n_epochs+1):
                metadata.append({"subject": i, "session": session, "epoch_index": e})

    # Saving the concatenated data
    concatenated_epochs = np.concatenate(all_epochs,axis=0)
    print(f"Se concatenaron {len(all_epochs)} archivos.")
    print(f"Forma final del array concatenado: {concatenated_epochs.shape}")

    mat_out = os.path.join(in_out_root,"epochs_concatenados.mat")
    scipy.io.savemat(mat_out, {"epochs": concatenated_epochs})


    # Saving the Metadata in a CSV
    metadata_out = os.path.join(in_out_root, "epoch_metadata.csv")
    with open(metadata_out, mode='w', newline='') as file:
        writer = csv.DictWriter(file, fieldnames=["subject", "session", "epoch_index"])
        writer.writeheader()
        writer.writerows(metadata)
    print(f"Metadata guardada en: {metadata_out}")


def concatenate_labels(in_out_root, n_subjects, n_sessions, labeling):
    
    '''
    This script will put all the labels in just one .csv file
    Args:
        in_out_root (str): Path to all the data (in_out_root/Subject_XX/Session_XX/Data)
        n_subjects (int): Number of subjects data to concatenate
        n_sessions (int): Number of sessions of each subject to concatenate
        labeling (str): Name for the type of labeling. For example, if we have grouped the markers in just "numbers and words" labeling will be numbers_vs_words.csv
    
    Returns:
        None
    '''

    all_labels = []

    for i in range(1,n_subjects+1):
        subject = f'Subject_{i:02d}'


        for session in range(1, n_sessions+1):
            # Obtaining the path
            session_name = f'Session_{session:02d}'
            session_in_path = os.path.join(in_out_root, subject, session_name)     

            labels_path= os.path.join(session_in_path,labeling)
            print(labels_path)

            # Grouping the labels
            labels = pd.read_csv(labels_path, header=None) #ojo con los headers 
            all_labels.append(labels)

    # Saving the concat labels        
    labels_concat = pd.concat(all_labels, axis=0, ignore_index=True)
    print(f"Se concatenaron {len(labels_concat)} archivos.")
    print(f"Forma final del array concatenado: {labels_concat.shape}")

    mat_out = os.path.join(in_out_root,labeling[:-4]+".mat")
    csv_out = os.path.join(in_out_root, labeling)
    scipy.io.savemat(mat_out, {"labels": labels_concat.to_numpy()})
    labels_concat.to_csv(csv_out, index=False, header=None)
