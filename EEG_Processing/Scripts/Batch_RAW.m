%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Batch_Preprocessing.m iterates over subject/session folders produced by 
% the trimming/translation step and call `EEG_Preprocess_function` for each
% BitBrain session. This script is intended to be launched from 
% `Batch_Preprocessing.py`, which defines the workspace variables (root 
% / output paths and session counts).
%   For each subject/session it:
%     - locates the BitBrain session folder (BBT-E32*)
%     - builds input paths for EEG and event files
%     - creates output folders as needed
%     - calls `EEG_Preprocess_function` to perform channel filtering, epoching,
%       ICA and export of processed datasets.
%
% Usage:
%   This script is invoked from `Batch_Preprocessing.py` (MATLAB engine).
%   The Python driver must set the required workspace variables
%   before calling this script.
%
% Inputs (expected in the MATLAB workspace prior to running):
%   - root_dir    : string - root directory containing trimmed & translated
%                   subject folders (contains `Subject_*` directories).
%   - out_dir     : string - base directory where per-subject outputs will be
%                   created (script will create Subject_x/Session_x folders).
%   - loc_path    : string - path to channel locations file (.locs) used by
%                   `EEG_Preprocess_function`.
%   - n_sessions  : integer - number of sessions to iterate per subject.
%   - n_subjects  : integer - (optional) expected number of subjects; not
%                   strictly required by this script but commonly set.
%
% Behavior / Side-effects:
%   - Iterates directories matching `Subject_*` under `root_dir`.
%   - For each session named `Session_##`, searches for subfolders matching
%     `BBT-E32*` (BitBrain session folders). For each such folder it:
%       * sets `EEG_in_path = fullfile(bbt_path,'EEG.csv')`
%       * sets `epochs_path = fullfile(session_path, 'epoch_eeglab.txt')`
%       * calls EEG_Preprocess_function(EEG_in_path, session_out_path, loc_path, epochs_path, 256)
%       * pauses 5 seconds between calls
%   - Creates missing output directories (`out_dir/Subject_x/Session_x`) as needed.
%   - Prints progress messages to the console (e.g., "Processing <path>").
%
% Outputs:
%   - Per-subject, per-session output folders under `out_dir` (created if needed).
%   - Final data files are produced by `EEG_Preprocess_function` and saved
%     into each session's `session_out_path`. Typical files produced by that
%     function include (saved to the session out folder):
%       * EEG.csv
%       * Complete.set
%       * Complete_epoched.set
%       * Correct_epochs.set
%       * Correct_epochs.mat
%       * Correct_labels.csv
%
% Notes / Dependencies:
%   - This script expects to be run from a MATLAB session whose workspace
%     already contains `root_dir`, `out_dir`, `loc_path`, `n_sessions` (and
%     optionally `n_subjects`)—these are provided by
%     `Batch_Preprocessing.py` when it invokes MATLAB/EEGLAB.
%   - Relies on `EEG_Preprocess_function`.
%   - Global `eeg` variable is declared here because EEGLAB routines used by
%     the preprocessing function require it.
%
% Author: Mario Lobo (UPM)
% Email:  mario.lobo.alonso@alumnos.upm.es
% Version: 27-10-2025
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Global variable beacuse it does not work without it
global eeg
fs = 256;

% root_dir, out_dir, loc_path, n_sesisons and n_subjects is defined in
% Batch_preprocessing.py
subjects = dir(fullfile(root_dir, 'Subject_*'));

% It will iterate for all the subjects
for i = 1:length(subjects)
    %If the item is not a directory, continue
    if ~subjects(i).isdir
        continue
    end
    
    %obtain the path of a subject
    subject_id = subjects(i).name;
    subject_path = fullfile(root_dir, subjects(i).name);
    subject_out_path = fullfile(out_dir, subjects(i).name);
    
    % Create out path if it does no exist
    if ~isfolder(subject_out_path)
        mkdir(subject_out_path);
    end

    % Iterate for all the sessions
    for session_num = 1:n_sessions
        % Obtain the name and path to the session
        session_name = sprintf('Session_%02d', session_num);
        session_path = fullfile(subject_path, session_name);
        session_out_path = fullfile(subject_out_path, session_name);
        if ~isfolder(session_path)
            continue
        end
        
        % Creates the output session folder
        if ~isfolder(session_out_path)
            mkdir(session_out_path);
        end
       

        % Obtain the path to the EEG.csv
        bbt_folders = dir(fullfile(session_path, 'BBT-E32*'));
        for j = 1:length(bbt_folders)
            if ~bbt_folders(j).isdir
                continue
            end
            bbt_path = fullfile(session_path, bbt_folders(j).name);
            
            % Defining EEG and epochs path
            fprintf('Processing %s\n', bbt_path);
            EEG_in_path = fullfile(bbt_path,'EEG.csv');
            epochs_path = fullfile(session_path, 'epoch_eeglab.txt');
            
            % Preprocess for that subject and session
            EEG_RAW_function(EEG_in_path,session_out_path ,loc_path,epochs_path,fs, subject_id, session_name);
            pause(5); 
        end
    end
end
