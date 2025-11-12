function EEG_Preprocess_function(EEG_in_path, out_path,loc_path,epochs_path, fs)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% EEG_Preprocess_function.m preprocess BitBrain-style EEG CSV data and 
% produce filtered continuous and epoched datasets ready for analysis.
% The pipeline includes:
%     - CSV import (BitBrain RAW format)
%     - Basic FIR filtering (high-pass 1 Hz, low-pass 100 Hz)
%     - 50 Hz notch filtering
%     - Segment cleaning (pop_clean_rawdata / ASR-style)
%     - Re-referencing to average
%     - Event import and epoching (window: [-2 3] s)
%     - Adaptive narrowband notch filtering (uses adaptiveNotch.m)
%     - ICA (runica), ICLabel, flagging/removal of EOG components
%     - Export of continuous and epoched datasets and metadata
%
% Usage:
%   EEG_Preprocess_function(EEG_in_path, out_path, loc_path, epochs_path, fs)
%
% Inputs:
%   EEG_in_path  - string: Path to BitBrain raw CSV file. Expected to
%                  contain a 'steady_timestamp' column and channel columns.
%                  The script removes columns named 'sequence', 'battery',
%                  and 'flags' if present.
%   out_path     - string: Directory where output files will be saved.
%   loc_path     - string: Path to a channel locations file (.locs) usable
%                  by EEGLAB (channel order must match CSV channel columns).
%   epochs_path  - string: Path to events/epoch file to be read by
%                  pop_importevent. The code expects fields
%                  {'latency','type','position','session'} and uses
%                  'timeunit',1e-06 (microseconds) and 'skipline',1.
%   fs           - numeric: Sampling rate (Hz) of the EEG recording.
%
% Outputs (saved to out_path):
%   - EEG.csv               : Filtered continuous EEG exported as CSV.
%                             First column 'steady_timestamp', then channel cols.
%   - Complete.set          : Continuous EEGLAB dataset (filtered + events).
%   - Complete_epoched.set  : EEGLAB dataset after epoching.
%   - Correct_epochs.set    : Epoched dataset after ICA/component removal.
%                             Contains all the technically correct epochs.
%                             Script Batch_epoch_selection is then used to
%                             inspect the data and discard noisy epochs.
%   - Correct_epochs.mat    : .mat file containing variable 'epochs' (chan x samples x trials).
%   - Correct_labels.csv    : CSV file with columns [EpochIndex, EventType, EventPosition]
%                             for the correct epochs.
%
% Notes / Dependencies:
%   - Requires EEGLAB and plugins: ICLabel, clean_rawdata (on MATLAB path).
%   - Requires local helper script 'adaptiveNotch.m'.
%   - Event names for epoching are hard-coded in the script; update them if
%     your events use different labels.
%   - Warning: pop_importevent uses timeunit=1e-06; ensure event latencies
%     in your file match that unit or change the argument accordingly.
%
% Author: Mario Lobo (UPM)
% Email:  mario.lobo.alonso@alumnos.upm.es
% Version: 27-10-2025
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


    %Delete previus EEGlab Info (as the function is being called
    %recursively)
    close all
    clear EEG
    clear ALLEEG
    clear CURRENTSET

    %eeg will store the EEG.csv data, but it has to be a global variable so
    %EEGLab can read it
    global eeg

    %Read EEG CSV
    %Saving only the important information from csv (WARNING: only works
    %with BitBrain RAW format)
    csv = readtable(EEG_in_path);
    csv.sequence = [];
    csv.battery = [];
    csv.flags = [];
    
    
    %Clean the timestamps to easily save the data into an array (save
    %before the timestamps in a vector)
    steady_timestamps = csv.steady_timestamp;
    csv.steady_timestamp = [];
    eeg = table2array(csv)';
    
    eeg = eeg*1000; %BitBrain data is stored in mV and EEGLab reads microVolts

    %Clear the table as we have everything in different variables
    clear("csv");
    
    % EEGLAB start
    [ALLEEG EEG CURRENTSET ALLCOM] = eeglab;
    
    %Importing the data into eeglab
    EEG = pop_importdata('dataformat','array','nbchan',size(eeg,1),'data','eeg','srate',fs,'pnts',size(eeg,2),'xmin',0,'chanlocs',char(loc_path));
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 0,'setname','RAW_data','gui','off'); 




    % Basics filters of data
    %High-pass filter (FIR filter, order auto-selected). Removes DC
    EEG = pop_eegfiltnew(EEG, 'locutoff',1,'plotfreqz',0);
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'setname','high-passed','overwrite','on','gui','off');

    %Low-pass filter (FIR filter, order auto-selected). Removes high
    %frequency
    EEG = pop_eegfiltnew(EEG, 'hicutoff',100,'plotfreqz',0);
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'setname','high-low-passed','overwrite','on','gui','off');

    %Notch filter 50Hz (FIR filter, order auto-selected). Removes line
    %noise
    EEG = pop_eegfiltnew(EEG, 'locutoff',49,'hicutoff',51,'revfilt',1,'plotfreqz',0);
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'setname','hp+notch','overwrite','on','gui','off'); 



    % Segment reconstruction before doing the re-referencing (see
    % https://sccn.ucsd.edu/githubwiki/files/asr-final-export.pdf slide 5)
    EEG = pop_clean_rawdata(EEG, 'FlatlineCriterion','off','ChannelCriterion','off','LineNoiseCriterion','off','Highpass','off','BurstCriterion',25,'WindowCriterion','off','BurstRejection','off','Distance','Euclidian');
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'setname','rejected','overwrite','on','gui','off'); 



    %Re-referencing
    EEG = pop_reref( EEG, []);
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'setname','filtered and re-referenced','overwrite','on','gui','off'); 
    

    
    % For ICA and extra notch filters (peaks detected after internal
    % testing), the epoched signals will be used since there are noisy data
    % from between tasks. For future projects: record each sesion in one
    % file and then merge them.

    %Import the epoch file (the events, without repeated ones)
    EEG = pop_importevent( EEG, 'event',char(epochs_path),'fields',{'latency','type','position','session'},'skipline',1,'timeunit',1e-06);
    [ALLEEG, EEG, CURRENTSET] = eeg_store(ALLEEG, EEG, CURRENTSET);

    % Save the dataset with everything basic filtered data, channels and events
    % (but not epoched)
    EEG = pop_saveset( EEG, 'filename','Complete.set','filepath',out_path);
    [ALLEEG, EEG, CURRENTSET] = eeg_store(ALLEEG, EEG, CURRENTSET);

    
    %saving the same EEG data as Complete.set but in .csv
    complete_EEG = EEG.data';

    %Save the steady timestamps and filtered data into a table with
    %headers. This is just continuous filtered EEG, without markers or
    %epochs
    exit_csv = array2table([string(steady_timestamps) complete_EEG]);
    exit_csv.Properties.VariableNames = (["steady_timestamp" string({EEG.chanlocs.labels})]);

    % Export table
    writetable(exit_csv, append(out_path, '\EEG.csv'), "QuoteStrings","none");




    %Extract the epochs
    EEG = pop_epoch( EEG, { 'Baja_el_volumen_os','Sube_el_volumen_os', 'Silencia_FireTV_os', 'Enciende_la_televisión_os', 'Apaga_FireTV_os', 'Turn_down_volume_os','Turn_up_volume_os', 'Mute_FireTV_os', 'Turn_on_television_os', 'Turn_off_FireTV_os','Baja_el_volumen_cs','Sube_el_volumen_cs', 'Silencia_FireTV_cs', 'Enciende_la_televisión_cs', 'Apaga_FireTV_cs', 'Turn_down_volume_cs','Turn_up_volume_cs', 'Mute_FireTV_cs', 'Turn_on_television_cs', 'Turn_off_FireTV_cs'  }, [-2  3], 'newname', 'Epochs', 'epochinfo', 'yes');
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'overwrite','on','gui','off'); 

    %If any event or epoch can not be extracted, or if different events aim to the same epoch, creates a
    %correct_labels.txt file with the labels in order

    labels = strings(0,1);
    not_used = [];
    for i = 1:EEG.trials
        %if it is a cell, then more than one event is in the same epoch
        if length(EEG.epoch(i).event)>1
            not_used = [not_used i];
        else
            new_label = EEG.epoch(i).eventtype;
            labels(end+1) = string(new_label);
        end
    end




    % Now, we apply a bunch of adaptive filters. They will compute the DSP
    % of each trial and calculate the mean. With that, it will look for a
    % peak inside a "search region" and if the peak power differs more than
    % a threshold (in dB) from the average power of the region, a filter
    % will be applied centered in that frequency.

    %Reason of using this is because of internal testing showed noise in
    %80.5Hz, but not stable for all the subjects, some where at 80Hz, other
    %at 82Hz.
    applied = true;
    while applied == true
        [EEG, f0, applied] = adaptiveNotch(EEG, [70 90], 3, false);
    end
    [EEG, f0, applied] = adaptiveNotch(EEG, [40 60], 4, false);
    % Saving new dataset
    [ALLEEG, EEG, CURRENTSET] = pop_newset(ALLEEG, EEG, 1, 'setname','extra-notch','overwrite','on','gui','off');


    %Save the dataset as before but epoched
    EEG = pop_saveset( EEG, 'filename','Complete_epoched.set','filepath',out_path);
    [ALLEEG, EEG, CURRENTSET] = eeg_store(ALLEEG, EEG, CURRENTSET);

    %Discart epochs that might have multiple events associated
    EEG.epoch(not_used) = [];
    EEG.data(:,:,not_used) = [];


    % Independent Component Analysis
    % Extract ICA components (default from eeglab)
    EEG = pop_runica(EEG, 'icatype', 'runica', 'extended',1,'rndreset','yes','interrupt','on');
    [ALLEEG, EEG, CURRENTSET] = eeg_store(ALLEEG, EEG, CURRENTSET);

    % Label components with probability of being noise
    EEG = pop_iclabel(EEG, 'default');
    [ALLEEG, EEG, CURRENTSET] = eeg_store(ALLEEG, EEG, CURRENTSET);

    % See the components classification
    % pop_viewprops(EEG, 0)
    % pop_viewprops( EEG, 0, [1:31], {'freqrange', [1 100]}, {}, 1, 'ICLabel' );

    %Flag components related to EOG as noise (if probability between 0.7
    %and 1)
    EEG = pop_icflag(EEG, [NaN NaN;NaN NaN; 0.7 1;NaN NaN;NaN NaN;NaN NaN;NaN NaN]);
    [ALLEEG, EEG, CURRENTSET] = eeg_store(ALLEEG, EEG, CURRENTSET);

    %Remove components marked as noise
    %Array [] empty removes the components flagged as noise. If we add values,
    %then it will remove the indicated components
    %It will not ask for confirmation (the 0 indicated)
    EEG = pop_subcomp( EEG, [], 0);
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'setname','ICAed','overwrite','on','gui','off');



    %Save a .mat with the separated epochs in a 3D array. This epochs match
    %the correct_epochs labels and has IC correction
    epochs = EEG.data;
    save(append(out_path, '\Correct_epochs.mat'),"epochs")

    %Save the Dataset without the bad epochs and events
    EEG = pop_saveset( EEG, 'filename','Correct_epochs.set','filepath',out_path);
    [ALLEEG, EEG, CURRENTSET] = eeg_store(ALLEEG, EEG, CURRENTSET);

    %Save the labels and metadata associated with the epochs without errors
    epoch_labels_file = fullfile(out_path, 'Correct_labels.csv');
    fid = fopen(epoch_labels_file, 'w');
    fprintf(fid, 'EpochIndex,EventType,EventPosition\n');

    for e = 1:length(EEG.epoch)
        ev_type = EEG.epoch(e).eventtype;        % solo un evento por epoch
        ev_pos  = EEG.epoch(e).eventposition;     % posición del evento
        fprintf(fid, '%d,%s,%d\n', e, ev_type, ev_pos);
    end

    fclose(fid);
    fprintf('Etiquetas de epochs guardadas en: %s\n', epoch_labels_file);


end