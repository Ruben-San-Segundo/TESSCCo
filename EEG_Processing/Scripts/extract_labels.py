"""
This file contains some options for label extraction in specific files. That means, once know the labels that are associated to Trials that we can not use (for some reason), we discart them and obtain a "correct" subset of markers.
This Script changes the markers/labels into a different form we may want. For example, if we want to compare numbers vs words, the script will change all the "Baja_el_volumen_cs", "Baja_el_volumen_os", etc. into "Spanish".

This allows to make different experiments (numbers vs words, os vs cs, classification without cs/os into account, complete classification)
"""

"""
extract_labels.py provide small helper functions to derive analysis-friendly label columns
from per-session Clean_labels.csv files produced after epoch cleaning.
These helpers add new columns to the same CSV file (overwriting it) to
represent higher-level groupings such as:
- covert vs overt speech (os_cs)
- command-level tokens (vocabulary) (Command)
- language label (language)

That way, different analyses can be performed by selecting the appropriate label column.


Functions:
    - covert_vs_overt(clean_labels_file_path)
    Adds column os_cs with values 'os' (overt), 'cs' (covert), or None.
    - just_words(clean_labels_file_path)
    Adds column Command mapping full EventType labels to a canonical
    command name (vocabulary token), collapsing cs/os variants.
    - english_vs_spanish(clean_labels_file_path)
    Adds column language with values 'Spanish', 'English', or None.

Inputs:
    - clean_labels_file_path (str): Path to a CSV with at least the column
    'EventType' (the script expects header row and comma-separated format).

Outputs:
    - Each function overwrites the same CSV file adding a new column.


Dependencies:
    - The EventType column in the CSV must contain the expected labels
    (e.g., 'Baja_el_volumen_cs', 'Turn_down_volume_os', etc.).
    - The just_words mapping relies on the hard-coded dictionary in the
    function; update it if your vocabulary set changes.

Author:
Mario Lobo (UPM)
mario.lobo.alonso@alumnos.upm.es
Version:
27-10-2025
"""

import pandas as pd


def covert_vs_overt(clean_labels_file_path):
    """
    Add a covert/overt speech column to a Clean_labels CSV. It read the CSV at
    clean_labels_file_path, verify the presence of the 'EventType' column, and 
    create a new column `os_cs` that classifies each epoch as 'os' (overt speech) or 'cs' (covert speech)

    Args:
        clean_labels_file_path (str): Path to the CSV file with cleaned epoch labels.
                                    Must contain column 'EventType'.

    Returns:
        None (the function overwrites the input CSV with the added column).
    """


    # Load the original CSV with header
    df = pd.read_csv(clean_labels_file_path, sep=",")

    # Check if 'EventType' column exists
    if "EventType" not in df.columns:
        raise ValueError("El archivo no contiene la columna 'EventType'.")

    # Create the new column based on the 'os' or 'cs' suffixes
    df["os_cs"] = df["EventType"].apply(
        lambda x: "os" if isinstance(x, str) and x.endswith("os")
        else ("cs" if isinstance(x, str) and x.endswith("cs") else None)
    )

    # Save back to the same file (overwriting)
    df.to_csv(clean_labels_file_path, sep=",", index=False)

    print(f"'os_cs' column added to file: {clean_labels_file_path}")


def just_words(clean_labels_file_path):
    """
    Collapse cs/os variants into a canonical command (vocabulary) label.
    It reads clean_labels_file_path and creates a `Command` column that maps
    fine-grained EventType labels (which include cs/os suffixes, e.g., 'Baja_el_volumen_cs') to a
    canonical command token (e.g., 'Baja_el_volumen').

    Args:
        clean_labels_file_path (str): Path to the CSV file with cleaned epoch labels.
    """


    # Load original CSV with header
    df = pd.read_csv(clean_labels_file_path, sep=",")

    # Check if 'EventType' column exists
    if "EventType" not in df.columns:
        raise ValueError("El archivo no contiene la columna 'EventType'.")

    # Mapping dictionary: each key is the final category
    # each value is a list of types that should be mapped to that category
    mapping = {
        "Baja_el_volumen": ["Baja_el_volumen_cs", "Baja_el_volumen_os"],
        "Sube_el_volumen": [ "Sube_el_volumen_cs", "Sube_el_volumen_os"],
        "Silencia_FireTV": ["Silencia_FireTV_cs", "Silencia_FireTV_os"],
        "Enciende_la_televisión": ["Enciende_la_televisión_cs", "Enciende_la_televisión_os"],
        "Apaga_FireTV": ["Apaga_FireTV_cs", "Apaga_FireTV_os"],
        "Turn_down_volume": ["Turn_down_volume_cs", "Turn_down_volume_os"],
        "Turn_up_volume": ["Turn_up_volume_cs", "Turn_up_volume_os"],
        "Turn_off_FireTV": ["Turn_off_FireTV_cs", "Turn_off_FireTV_os"],
        "Mute_FireTV": ["Mute_FireTV_cs", "Mute_FireTV_os"],
        "Turn_on_television": ["Turn_on_television_cs", "Turn_on_television_os"]
    }

    # Create an auxiliary function to map each EventType
    def map_event_type(event_type):
        if not isinstance(event_type, str):
            return None
        for label, variants in mapping.items():
            if event_type in variants:
                return label
        return None

    # Apply the mapping to the EventType column
    df["Command"] = df["EventType"].apply(map_event_type)

    # Save the file (overwriting)
    df.to_csv(clean_labels_file_path, sep=",", index=False)

    print(f"'Command' column added to file: {clean_labels_file_path}")



def english_vs_spanish(clean_labels_file_path):
    """
    Add a language label column classifying EventType as English or Spanish.
    It reads the CSV and creates a `language` column set to 'Spanish' if the
    EventType belongs to the Spanish set, 'English' if it belongs to the English set

    Args:
        clean_labels_file_path (str): Path to the CSV file with cleaned epoch labels.

    Returns:
        None (overwrites the input CSV with the new `language` column).
    """

    # Load original CSV with header
    df = pd.read_csv(clean_labels_file_path, sep=",")

    # Check if 'EventType' column exists
    if "EventType" not in df.columns:
        raise ValueError("El archivo no contiene la columna 'EventType'.")

    # Define lists for events by language
    spanish_events = [
        "Baja_el_volumen_cs", "Baja_el_volumen_os",
        "Sube_el_volumen_cs", "Sube_el_volumen_os",
        "Silencia_FireTV_cs", "Silencia_FireTV_os",
        "Enciende_la_televisión_cs", "Enciende_la_televisión_os",
        "Apaga_FireTV_cs", "Apaga_FireTV_os"
    ]

    english_events = [
        "Turn_down_volume_cs", "Turn_down_volume_os",
        "Turn_up_volume_cs", "Turn_up_volume_os",
        "Turn_off_FireTV_cs", "Turn_off_FireTV_os",
        "Mute_FireTV_cs", "Mute_FireTV_os",
        "Turn_on_television_cs", "Turn_on_television_os"
    ]

    # Auxiliary function to map each event type to a language
    def map_language(event_type):
        if not isinstance(event_type, str):
            return None
        if event_type in spanish_events:
            return "Spanish"
        elif event_type in english_events:
            return "English"
        else:
            return None

    # Apply the mapping
    df["language"] = df["EventType"].apply(map_language)

    # Save the file (overwriting)
    df.to_csv(clean_labels_file_path, sep=",", index=False)

    print(f"'language' column added to file: {clean_labels_file_path}")