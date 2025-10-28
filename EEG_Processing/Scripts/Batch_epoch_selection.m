%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Batch_epoch_selection.m iterates over subject/session folders containing
% `Correct_epochs.set`. It loads each dataset, provides interactive tools 
% for manual and visual event/epoch cleaning, save cleaned datasets and epoch
% matrices, and produce per-session and global summaries of epoch counts 
% by event type.
%
%   Specifically, for every `Subject_*/Session_*` folder containing
%   `Correct_epochs.set`, the script:
%     1. Loads the EEGLAB dataset (Correct_epochs.set).
%     2. Opens an event editor GUI (`pop_editeventvals`) so the user can
%        delete undesired events (in our case, following an excel with notes
%        taken during experiments).
%     3. Removes epochs without associated events (`pop_selectevent`).
%     4. Opens a visual inspection window (`pop_eegplot`) to allow manual
%        epoch rejection by eye.
%     5. Saves the cleaned EEGLAB dataset (`Clean_epochs.set`) and a 3D .mat
%        file (`Clean_epochs.mat`) containing `EEGdata` (channels x timepoints x epochs).
%     6. Writes a per-session CSV of the kept epoch labels (`Clean_labels.csv`).
%     7. Appends a summary row to `epochs_summary.csv` with epoch counts at
%        each step and the final counts for each known event type.
%
% Usage:
%   Run this script from MATLAB. The script prompts for a parent folder
%   (using `uigetdir`) which must contain `Subject_*` directories. Example:
%     - Parent folder structure: Parent/Subject_01/Session_01/.../Correct_epochs.set
%   Launch the script directly in MATLAB (no function call required).
%
% Inputs:
%   - The script prompts for `root_path` (parent folder containing Subject_*).
%
% Outputs:
%   - epochs_summary.csv (saved in the chosen `root_path`):
%       Columns: Subject,Session,Epochs_initial,Epochs_after_events,Epochs_after_visual,<event-type counts...>
%   - For each processed session folder:
%       * Clean_epochs.set      - EEGLAB dataset after manual cleaning
%       * Clean_epochs.mat      - variable `EEGdata` (channels x time x epochs) saved with -v7.3
%       * Clean_labels.csv      - per-epoch metadata: Subject,Session,EpochIndex,EventType,EventPosition
%
% Event types and labels:
%   - The script contains a hard-coded list `all_labels` enumerating the
%     known event labels used to count final epoch numbers. 
%
% Dependencies:
%   - EEGLAB (must be installed and on MATLAB path)
%
% Interaction notes:
%   - During event editing the `pop_editeventvals` GUI is used to remove
%     unwanted events. After closing it, the script removes epochs without
%     events using `pop_selectevent`.
%   - During visual inspection the `pop_eegplot` window opens; click "Reject"
%     to finalize epoch rejections.
%   - The script waits for the EEGPLOT window to close before proceeding.
%
% Cautions:
%   - If `Correct_epochs.set` is missing in a session folder, the script
%     prints a message and skips that session.
%   - If many epochs are removed, downstream analysis may have insufficient
%     trials; check `epochs_summary.csv` for per-session counts.
%   - `Clean_epochs.mat` is saved with -v7.3 to support large arrays.
%
% Author: Mario Lobo (UPM)
% Email:  mario.lobo.alonso@alumnos.upm.es
% Version: 27-10-2025
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear; close all; clc;

% === Set-up ===
root_path = uigetdir(pwd, 'Select the parent folder with Subject_XX structure inside'); % Parent folder

% Creates the CSV where the number of epochs will be stored
output_csv = fullfile(root_path, 'epochs_summary.csv');
fid = fopen(output_csv, 'w');
fprintf(fid, 'Subject,Session,Epochs_initial,Epochs_after_events,Epochs_after_visual');

all_labels = {'Baja_el_volumen_os','Sube_el_volumen_os', 'Silencia_FireTV_os', 'Enciende_la_televisión_os', 'Apaga_FireTV_os', 'Turn_down_volume_os','Turn_up_volume_os', 'Mute_FireTV_os', 'Turn_on_television_os', 'Turn_off_FireTV_os','Baja_el_volumen_cs','Sube_el_volumen_cs', 'Silencia_FireTV_cs', 'Enciende_la_televisión_cs', 'Apaga_FireTV_cs', 'Turn_down_volume_cs','Turn_up_volume_cs', 'Mute_FireTV_cs', 'Turn_on_television_cs', 'Turn_off_FireTV_cs'};

for i = 1:numel(all_labels)
    fprintf(fid,',%s', all_labels{i});
end
fprintf(fid,'\n');
fclose(fid);


% EEGLAB start
[ALLEEG EEG CURRENTSET ALLCOM] = eeglab;


% === Loop for each subject and session ===
subjects = dir(fullfile(root_path, 'Subject_*'));
for s = 1:length(subjects)
    % Obtain subject's path (or continue if it doesn't exist)
    subj_path = fullfile(root_path, subjects(s).name);
    if ~subjects(s).isdir, continue; end

    % Obtain all the Sessions' paths for that subject and iterate
    sessions = dir(fullfile(subj_path, 'Session_*'));
    for sess = 1:length(sessions)
        sess_path = fullfile(subj_path, sessions(sess).name);
        if ~sessions(sess).isdir, continue; end

        % Dataset path for that subject's session
        set_file = dir(fullfile(sess_path, 'Correct_epochs.set'));%_epoched
        if isempty(set_file)
            fprintf('No se encontró dataset en %s\n', sess_path);
            continue;
        end

        set_path = fullfile(sess_path, set_file(1).name);
        fprintf('\nProcesando %s...\n', set_path);

        % === 1. Load existing dataset ===
        EEG = pop_loadset(set_path);
        EEG = eeg_checkset(EEG);
        n_init = EEG.trials;

        % === 2. Open GUI for deleting not wanted events ===
        EEG = pop_editeventvals(EEG);
        EEG = eeg_checkset(EEG);

        % Delete epochs without asociated event 
        EEG = pop_selectevent( EEG, 'deleteevents','off','deleteepochs','on','invertepochs','off');
        EEG = eeg_checkset(EEG);

        % Save number of epochs
        n_after_events = EEG.trials;


        % === 3. Visual inspection ===
        % Opens the GUI for visual inspection
        pop_eegplot(EEG, 1, 1, 1);
        disp('Visual inspection window opened. Close EEGLab window clicking "Reject" once you finish...');
        
        % Wait until the window is colsed
        while ~isempty(findobj('tag', 'EEGPLOT'))
            pause(1);
        end
        
        % When window is closed, apply rejections
        EEG = eeg_checkset(EEG);
        
        % Save number of epochs
        n_after_visual = EEG.trials;


        % === 4a. Save the results in a dataset ===
        [~, setname, ~] = fileparts(set_file(1).name);
        cleaned_name = 'Clean_epochs.set';
        EEG = pop_saveset(EEG, 'filename', cleaned_name, 'filepath', sess_path);

        % === 4b. Save the results in 3D .mat ===
        mat_file = fullfile(sess_path, 'Clean_epochs.mat');
        EEGdata = EEG.data;  % channels x timepoints x epochs
        save(mat_file, 'EEGdata', '-v7.3');
        fprintf('EEG.data 3D array saved in: %s\n', mat_file);

        % === 5. Save the final labels in a .csv for each session and subject ===
        epoch_labels_file = fullfile(sess_path, 'Clean_labels.csv');
        fid2 = fopen(epoch_labels_file, 'w');
        fprintf(fid2, 'Subject,Session,EpochIndex,EventType,EventPosition\n');
        
        for e = 1:length(EEG.epoch)
            ev_type = EEG.epoch(e).eventtype;
            ev_pos  = EEG.epoch(e).eventposition;
            fprintf(fid2, '%s,%s,%d,%s,%d\n', ...
                subjects(s).name, sessions(sess).name, e, ev_type, ev_pos);
        end
        
        fclose(fid2);
        fprintf('clean epochs saved in: %s\n', epoch_labels_file);

        
        % === 6. Update global summary with the final number of each eventType ===
        event_types = {EEG.epoch.eventtype};
        [types_unique, ~, idx] = unique(event_types); 
        counts = histc(idx, 1:numel(types_unique));
        
        % === Count final labels ===
        event_types = {EEG.epoch.eventtype};
        counts = zeros(1, numel(all_labels));
        for i = 1:numel(all_labels)
            counts(i) = sum(strcmp(event_types, all_labels{i}));
        end

        % Save all the final information (number of epochs after each step and final number of each eventType)  
        fid = fopen(output_csv,'a');
        fprintf(fid,'%s,%s,%d,%d,%d', subjects(s).name, sessions(sess).name, n_init, n_after_events, n_after_visual);
        for i = 1:numel(counts)
            fprintf(fid,',%d', counts(i));
        end
        fprintf(fid,'\n');
        fclose(fid);
    end
end

fprintf('\nProcess completed. Results saved in %s\n', output_csv);
