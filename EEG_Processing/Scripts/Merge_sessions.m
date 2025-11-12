%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Merge_sessions.m finds per-session cleaned datasets (`Clean_epochs.set`)
% and combine them into a single per-subject dataset (`Merged_Clean_epochs.set`).
% The typical use-case merges two sessions (Session_01 + Session_02) so the
% resulting dataset is easier to include in EEGLAB STUDY-level analyses.
% However, special cases (subjects with only one session) can be indicated.
%
%   Behavior:
%     - Iterates `Subject_*` directories under a configured `root_dir`.
%     - For each subject:
%         * If the subject is listed in `exclude_subjects_and_sessions`,
%           copy the single existing session's `Clean_epochs.set` to
%           `Merged_Clean_epochs.set` (no merge needed).
%         * Otherwise, load `Clean_epochs.set` from `Session_01` and
%           `Session_02` into EEGLAB, merge them with `pop_mergeset`, and
%           save the combined dataset as `Merged_Clean_epochs.set` in the
%           subject root folder.
%     - The script preserves event session information, so session identity
%       is not lost after merging.
%
% Usage:
%   Run directly in MATLAB. The script currently defines `root_dir`
%   inside the file. It requires EEGLAB to be installed and on the
%   MATLAB path.
%
% Inputs / configurable variables (in-script):
%   - `root_dir` : string - path containing the `Subject_*` folders to process.
%   - `n_sessions` : integer - number of sessions to expect (default: 2).
%   - `exclude_subjects_and_sessions` : Nx2 numeric matrix where each row
%        is [subjectIndex excludedSessionNumber]. For any listed subject,
%        the script will copy the other session's `Clean_epochs.set` to
%        `Merged_Clean_epochs.set` instead of merging.
%
% Outputs:
%   - Per-subject `Merged_Clean_epochs.set` saved in the subject root folder
%     (e.g., `Subject_01/Merged_Clean_epochs.set`).
%
% Dependencies:
%   - EEGLAB (must be on the MATLAB path).
%
% Notes, assumptions and cautions:
%   - The current script assumes two sessions per subject (Session_01 and
%     Session_02). To merge more sessions, update `n_sessions` and the
%     relevant indices passed to `pop_mergeset`.
%   - Some subjects may have only one session; these are handled by
%     `exclude_subjects_and_sessions` (copy instead of merge). The matrix
%     format is `[subjectIndex excludedSessionNumber]` (subject index is the
%     loop index used by the script).
%   - Session recordings may occur on different days; merged data may have
%     session-dependent differences (filtering/recording conditions). The
%     script assumes this is an acceptable risk for downstream STUDY
%     analyses.
%   - If `Clean_epochs.set` is missing for a required session, the subject
%     will be skipped (or a copy will not be created) and a warning is shown.
%
%
% Author: Mario Lobo (UPM)
% Email:  mario.lobo.alonso@alumnos.upm.es
% Version: 27-10-2025
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


clear; close all; clc;


% === Loop for all the subjects ===
root_dir = "C:\Users\user\Desktop\Mario Lobo\Silent Speech Data Amazon Non-Native\3. Pre-processed";
subjects = dir(fullfile(root_dir, 'Subject_*'));

n_sessions = 2;

% === There are subjects that don't have specific sessions for several
% reasons ===
exclude_subjects_and_sessions = [3 2;];

for i = 1:length(subjects)
    close all
    clearvars -except root_dir subjects n_sessions i exclude_subjects_and_sessions

    %If the item is not a directory, continue
    if ~subjects(i).isdir
        continue
    end
    
    %obtain the path of a subject
    subject_path = fullfile(root_dir, subjects(i).name);

    % Since we only have 2 sessions, if one subject appear to lack one
    % sesison then we only have to merge the other. Merge is no really
    % needed, we only copy the .set with a new name for compatibility with
    % other scripts (Create_study.m).
    row = find(exclude_subjects_and_sessions(:,1) == i, 1);
    if ~isempty(row)
        excluded_session = exclude_subjects_and_sessions(row,2);
        other_session = 3 - excluded_session; % 1→2, 2→1
         src_set = fullfile(subject_path, sprintf('Session_%02d', other_session), 'Clean_epochs.set');
         dest_set = fullfile(subject_path, 'Merged_Clean_epochs.set');

         if isfile(src_set)
            copyfile(src_set, dest_set);
            fprintf('Subject_%02d: copied from Session_%02d\n', i, other_session);
         else
             warning('Subject_%02d: Clean_epochs.set doesnt exist in Session_%02d. Copy not created.\n', i, other_session);
         end
            continue; % Skip the rest of the subject loop
     end


    % Call EEGLab
    [ALLEEG EEG CURRENTSET ALLCOM] = eeglab;


    % Iterate for the two sessions
    for session_num = 1:n_sessions
        %Obtain the name and path to the session
        session_name = sprintf('Session_%02d', session_num);
        session_path = fullfile(subject_path, session_name);


        %Load that dataset   
        if session_num == 1
            EEG = pop_loadset('filename','Clean_epochs.set','filepath',char(session_path));
            [ALLEEG, EEG, CURRENTSET] = eeg_store( ALLEEG, EEG, (session_num-1));
            % We have to store the old_path so we can "overwrite" the
            % dataset with itself. Thus, EEGLab will have the information
            % where to find this dataset to merge it with others
            old_path = fullfile(session_path,'Correct_epochs.set');
        else
            EEG = pop_loadset('filename','Clean_epochs.set','filepath',char(session_path));
            [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'saveold',char(old_path),'gui','off'); 
            % We save the actual path as "Old path" in case we have more
            % than two sessions. the explanation is the same as above.
            old_path = fullfile(session_path,'Correct_epochs.set');

        end   
    end
    % Merge the sessions and save the new .set
    merge_path = fullfile(subject_path, "Merged_Clean_epochs.set");
    % If we had more than 2 sessions, we will have to change the numbers
    % in brackets
    EEG = pop_mergeset( ALLEEG, [1  2], 0);
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 2,'savenew',char(merge_path),'gui','off'); 

end

