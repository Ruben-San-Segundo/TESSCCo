"""
This file contains some options for label extraction in specific files. That means, once know the labels that are associated to Trials that we can not use (for some reason), we discart them and obtain a "correct" subset of markers.
This Script changes the markers/labels into a different form we may want. For example, if we want to compare numbers vs words, the script will change all the "Baja_el_volumen_cs", "Baja_el_volumen_os", etc. into "Spanish".

This allows to make different experiments (numbers vs words, os vs cs, classification without cs/os into account, complete classification)
"""

import pandas as pd


def covert_vs_overt(correct_labels_file_path, labels_path):

    """
    Allows to compare Overt Speech and Covert Speech.
    Once all the labels are refered to the characteristic we want to analyze, an encoder will change the categorical labels into numeric labels
    
    Args:
        correct_labels_file_path (str): Path to the file with the correct labels
        labels_path (str): Path where the new labels (grouping characteristics) will be stored

    Returns:
        None
    """
    correct_labels_df = pd.read_csv(correct_labels_file_path, sep=" ", header=None)
    correct_labels_df.columns = ["type"]
    labels_categorical = []

    for _, row in correct_labels_df.iterrows():
        
        if row["type"][-2:] == "os":
            labels_categorical.append("os")
        elif row["type"][-2:] == "cs":
            labels_categorical.append("cs")
        else:
            continue

    #save the DataFrame to be exported
    labels_df = pd.DataFrame()
    labels_df["labels_categorical"] = labels_categorical
    #Export the labels file
    labels_df.to_csv(labels_path, sep=',', index=False, header=False)
    print("Labels file saved in: ", labels_path)



def all_labels(correct_labels_file_path, labels_path):
    """
   Allows to compare the vocabulary without differentiating between Overt Speech or Covert Speech.
   Once all the labels are refered to the characteristic we want to analyze, an encoder will change the categorical labels into numeric labels
    
    Args:
        correct_labels_file_path (str): Path to the file with the correct labels
        labels_path (str): Path where the new labels (grouping characteristics) will be stored

    Returns:
        None
    """
    correct_labels_df = pd.read_csv(correct_labels_file_path, sep=" ", header=None)
    correct_labels_df.columns = ["type"]
    categorical_labels = []
    for _, row in correct_labels_df.iterrows():
        if row["type"] == "Baja_el_volumen_cs" or row["type"] == "Baja_el_volumen_os":
                categorical_labels.append("Baja_el_volumen")
        elif row["type"] == "Sube_el_volumen_cs" or row["type"] == "Sube_el_volumen_os":
            categorical_labels.append("Sube_el_volumen")
        if row["type"] == "Silencia_FireTV_cs" or row["type"] == "Silencia_FireTV_os":
                categorical_labels.append("Silencia_FireTV")
        elif row["type"] == "Enciende_la_televisión_cs" or row["type"] == "Enciende_la_televisión_os":
            categorical_labels.append("Enciende_la_televisión")
        if row["type"] == "Apaga_FireTV_cs" or row["type"] == "Apaga_FireTV_os":
                categorical_labels.append("Apaga_FireTV")
        elif row["type"] == "Turn_down_volume_cs" or row["type"] == "Turn_down_volume_os":
            categorical_labels.append("Turn_down_volume")
        if row["type"] == "Turn_up_volume_cs" or row["type"] == "Turn_up_volume_os":
                categorical_labels.append("Turn_up_volume")
        elif row["type"] == "Turn_off_FireTV_cs" or row["type"] == "Turn_off_FireTV_os":
            categorical_labels.append("Turn_off_FireTV")
        if row["type"] == "Mute_FireTV_cs" or row["type"] == "Mute_FireTV_os":
                categorical_labels.append("Mute_FireTV")
        elif row["type"] == "Turn_on_television_cs" or row["type"] == "Turn_on_television_os":
            categorical_labels.append("Turn_on_television")
        else:
            continue

     #save the DataFrame to be exported
    labels_df = pd.DataFrame()
    labels_df["labels_os"] = categorical_labels
    #Export the labels
    labels_df.to_csv(labels_path, sep=',', index=False, header=False)
    print("Labels file saved in: ", labels_path)



def all_labels_cs_os(correct_labels_file_path, labels_path):
    """
    Allows to compare all the labels taking into accoun Overt Speech and Covert Speech. This function does nothing but copying the file with a new name 
    
    Args:
        correct_labels_file_path (str): Path to the file with the correct labels
        labels_path (str): Path where the new labels (grouping characteristics) will be stored

    Returns:
        None
    """
    correct_labels_df = pd.read_csv(correct_labels_file_path, sep=" ", header=None)
    correct_labels_df.columns = ["type"]
    #Export the labels (in a copied file with a new name)
    correct_labels_df.to_csv(labels_path, sep=',', index=False, header=False)
    print("Labels file saved in: ", labels_path)



 
def numbers_vs_words(correct_labels_file_path, labels_path):
    """
        Allows to compare between numbers and words without taking Overt Speech and Covert Speech into account.
        Once all the labels are refered to the characteristic we want to analyze, an encoder will change the categorical labels into numeric labels
        
        Args:
            correct_labels_file_path (str): Path to the file with the correct labels
            labels_path (str): Path where the new labels (grouping characteristics) will be stored

        Returns:
            None
    """
    
    correct_labels_df = pd.read_csv(correct_labels_file_path, sep=" ", header=None)
    correct_labels_df.columns = ["type"]
    labels_categorical = []
    for _, row in correct_labels_df.iterrows():
        
        if row["type"] == "Baja_el_volumen_cs" or row["type"] == "Baja_el_volumen_os" or row["type"] =="Sube_el_volumen_cs" or row["type"] == "Sube_el_volumen_os" or row["type"] =="Silencia_FireTV_cs" or row["type"] == "Silencia_FireTV_os" or row["type"] =="Enciende_la_televisión_cs" or row["type"] == "Enciende_la_televisión_os" or row["type"] =="Apaga_FireTV_cs" or row["type"] == "Apaga_FireTV_os":
            labels_categorical.append("Spanish")

        elif row["type"] == "Turn_down_volume_cs" or row["type"] == "Turn_down_volume_os" or row["type"] =="Turn_up_volume_cs" or row["type"] == "Turn_up_volume_os" or row["type"] =="Turn_off_FireTV_cs" or row["type"] == "Turn_off_FireTV_os" or row["type"] =="Mute_FireTV_cs" or row["type"] == "Mute_FireTV_os" or row["type"] =="Turn_on_television_cs" or row["type"] == "Turn_on_television_os":
            labels_categorical.append("English")

        else:
            continue


    #save the DataFrame to be exported
    labels_df = pd.DataFrame()
    labels_df["labels"] = labels_categorical
    #Export the labels
    labels_df.to_csv(labels_path, sep=',', index=False, header=False)
    print("Labels file saved in: ", labels_path)