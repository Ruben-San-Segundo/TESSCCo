"""
This code serves to find the epochs that we have deleted with Batch_epoch_selection in order to delete the same ones when using unprocessed data.
 Since they are not pre-processed (because we want them like that for DL) it is unfeasible to know if they are noisy or not.

    The script performs the following steps:
    1. Loads the `Correct_labels.csv` and `Clean_labels.csv` files for each subject/session in the Pre-processed directory.
    2. Identifies which epochs are present in `Correct_labels.csv` but not in `Clean_labels.csv`, indicating they were removed during the epoch selection process.
    3. Saves the identified removed epochs to a new CSV file `Removed_epochs.csv`
    4. The `Removed_epochs.csv` file can then be used to remove the same epochs from the RAW data in the Batch_RAW_epoch_selection.py script.

Author:
Mario Lobo (UPM)
mario.lobo.alonso@alumnos.upm.es
Version:
16-04-2026

"""
import os
import pandas as pd

def find_deleted_epochs(correct_labels_path, clean_labels_path, output_path):
    # ==============================
    # 1. Load files
    # ==============================

    correct = pd.read_csv(correct_labels_path)
    clean = pd.read_csv(clean_labels_path)

    # ==============================
    # 2. Select key columns
    # ==============================
    # These columns identify each epoch.
    # In Clean labels there are extra columns (Subject, Session),
    # but for comparison we use the common ones.

    key_cols = ["EventType", "EventPosition"]

    correct_keys = correct[key_cols]
    clean_keys = clean[key_cols]

    # ==============================
    # 3. Find deleted epochs
    # ==============================

    merged = correct_keys.merge(
        clean_keys,
        on=key_cols,
        how="left",
        indicator=True
    )

    removed_epochs = merged[merged["_merge"] == "left_only"]
    removed_epochs = removed_epochs.drop(columns=["_merge"])

    # ==============================
    # 4. Save result
    # ==============================

    removed_epochs.to_csv(output_path, index=False)

    print(f"\nNumber of deleted epochs: {len(removed_epochs)}")
    print(f"File saved to: {output_path}")


if __name__ == "__main__":
    # Example usage
    pre_processed_root = "C:/Users/user/Desktop/Mario Lobo/Silent Speech Data Amazon Non-Native/3. Pre-processed"

    n_subjects = 3
    n_sessions = 2

    not_process_subjects_and_sessions = [{"Subject_03", "Session_02"}] #List of subjects that will not be processed (for example, if they have corrupted data)

    #Go across all the subjects in the pre-processed folder to find the deleted epochs for each session
    for i in range(1,n_subjects+1):
        subject = f'Subject_{i:02d}'

        #Go across all the sessions for each subject
        for session in range(1, n_sessions+1):

            session_name = f'Session_{session:02d}'
            if {subject, session_name} in not_process_subjects_and_sessions:
                print(f"Skipping {subject} {session_name}. See documentation for issues.")
                continue

            correct_labels_path = os.path.join(pre_processed_root, subject, session_name, 'Correct_labels.csv')
            clean_labels_path = os.path.join(pre_processed_root, subject, session_name, 'Clean_labels.csv')
            removed_epochs_path = os.path.join(pre_processed_root, subject, session_name, 'Removed_epochs.csv')

            find_deleted_epochs(correct_labels_path, clean_labels_path, removed_epochs_path)
