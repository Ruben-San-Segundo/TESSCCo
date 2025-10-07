"""
Version 0.1

This script contains the sequence of steps to convert all the RAW EEG data from a subset of subjects with a determined number of sessions (same between subjects) to a file with the trials/epochs of every subject and every session.
It also generates a file with the labels in the same order as the epochs. This labels can be set to group characteristics (for example, numbers vs words).
If just a new label file wants to be created, comment lines 28 to 58
It is mandatory to include the folder path to the RAW data, the trimmed and translated and the finally pre-processed data.

There is major problem with this script. This is: if something goes wrong in the middle, it has to be started from the beginning (lines could be commented to avoid doing everithing again, but if label extraction fails in subject 7, all the subjects' labels will have to be recalculated)
"""

import trim_and_translate
import os
import matlab.engine as mtlb
import time
import extract_labels
import concatenate

raw_root = "C:/Users/user/Desktop/Mario Lobo/Silent Speech Data Amazon/1. RAW"
trimmed_and_translated_root = "C:/Users/user/Desktop/Mario Lobo/Silent Speech Data Amazon/2. Trimmed and Translated"
pre_processed_root = "C:/Users/user/Desktop/Mario Lobo/Silent Speech Data Amazon/3. Pre-processed"
# Path to the location file (it is usually the same for every subject)
loc_path = "C:/Users/user/Desktop/AMAZON_BCI/Code/Amazon_SSI/EEG_Processing/Scripts/BitBrain_SSI_placement.loc"

n_subjects = 20
n_sessions = 2

margin_trim = 512 #margin in samples for the trimming

label_extraction = "all_labels_cs_os.csv" #Options: "number_vs_words.csv", "os_vs_cs.csv", "all_labels.csv", "all_labels_cs_os.csv"

# Go across all the subjects for the trim and translation (step 1) 
for i in range(1,n_subjects+1):
    subject = f'Subject_{i:02d}'

    #Go across all the sessions for each subject
    for session in range(1, n_sessions+1):
        session_name = f'Session_{session:02d}'
        session_in_path = os.path.join(raw_root, subject, session_name)
        session_out_path = os.path.join(trimmed_and_translated_root, subject, session_name)

        trim_and_translate.execute(session_in_path,session_out_path,margin_trim)

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

#Once everything is MATLAB processed, the script continues with label extraction of the correct epochs 

# Go across all the subjects for the label extraction(step 3) 
for i in range(1,n_subjects+1):
    subject = f'Subject_{i:02d}'

    #Go across all the sessions for each subject
    for session in range(1, n_sessions+1):

        session_name = f'Session_{session:02d}'
        correct_labels_in_path = os.path.join(pre_processed_root, subject, session_name, 'correct_labels.txt')
        correct_labels_out_path = os.path.join(pre_processed_root, subject, session_name, label_extraction)
        
        if label_extraction == "numbers_vs_words.csv":
            extract_labels.numbers_vs_words(correct_labels_in_path, correct_labels_out_path)
        elif label_extraction == "os_vs_cs.csv":
            extract_labels.covert_vs_overt(correct_labels_in_path, correct_labels_out_path)
        elif label_extraction == "all_labels.csv":
            extract_labels.all_labels(correct_labels_in_path, correct_labels_out_path)
        elif label_extraction == "all_labels_cs_os.csv":
            extract_labels.all_labels_cs_os(correct_labels_in_path, correct_labels_out_path)



#finally, the concatenation of .mat epochs files and .mat label files is made (think how to make different concatenations (for example LOSO))
concatenate.concatenate_epochs(pre_processed_root, n_subjects, n_sessions)
concatenate.concatenate_labels(pre_processed_root, n_subjects, n_sessions, label_extraction)

print("ALL THE PRE-PROCESSING HAS ENDED")
        

