function EEG_Preprocess_function(EEG_in_path, out_path,loc_path,epochs_path, fs, subject_name, session_name)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% EEG_Preprocess_function.m preprocess BitBrain-style EEG CSV data and 
% produce filtered continuous and epoched datasets ready for analysis.
% The pipeline includes:
%     - CSV import (BitBrain RAW format)
%     - Event import and epoching (window: [-2 3] s)
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
%   - Correct_epochs.set    : Epoched dataset 
%   - Correct_epochs.mat    : .mat file containing variable 'epochs' (chan x samples x trials).
%   - Correct_labels.csv    : CSV file with columns [EpochIndex, EventType, EventPosition]
%                             for the correct epochs.
%
% Notes / Dependencies:
%   - Event names for epoching are hard-coded in the script; update them if
%     your events use different labels.
%   - Warning: pop_importevent uses timeunit=1e-06; ensure event latencies
%     in your file match that unit or change the argument accordingly.
%
% Author: Mario Lobo (UPM)
% Email:  mario.lobo.alonso@alumnos.upm.es
% Version: 16-04-2026
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
    
    % Add 3 channels full of 0 for interpolate Pz, O1, O2
    eeg = [eeg; zeros(1,length(eeg))];
    eeg = [eeg; zeros(1,length(eeg))];
    eeg = [eeg; zeros(1,length(eeg))];
    
    % EEGLAB start
    [ALLEEG EEG CURRENTSET ALLCOM] = eeglab;
    
    %Importing the data into eeglab
    EEG = pop_importdata('dataformat','array','nbchan',size(eeg,1),'data','eeg','srate',fs,'pnts',size(eeg,2),'xmin',0,'chanlocs',char(loc_path));
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 0,'setname','RAW_data','gui','off'); 

    EEG = pop_interp(EEG, [33  34  35], 'sphericalKang'); % SI NO FUNCIONA; PONER spherical A SECAS, SI NO planar
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'setname','RAW_interpolated','overwrite','on','gui','off'); 


    %Import the epoch file (the events, without repeated ones)
    EEG = pop_importevent( EEG, 'event',char(epochs_path),'fields',{'latency','type','position','session'},'skipline',1,'timeunit',1e-06);
    [ALLEEG, EEG, CURRENTSET] = eeg_store(ALLEEG, EEG, CURRENTSET);

    % Save the dataset with raw and events (but not epoched)
    EEG = pop_saveset( EEG, 'filename','Complete_raw.set','filepath',out_path);
    [ALLEEG, EEG, CURRENTSET] = eeg_store(ALLEEG, EEG, CURRENTSET);


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

    %Discart epochs that might have multiple events associated
    EEG.epoch(not_used) = [];
    EEG.data(:,:,not_used) = [];

    
    %Save a .mat with the separated epochs in a 3D array. This epochs match
    %the correct_epochs labels
    EEGData = EEG.data;
    [nCh, nSamp, nTrials] = size(EEGData);
    save(append(out_path, '\Correct_epochs.mat'),"EEGData")
    
    %Save the Dataset without the bad epochs and events
    EEG = pop_saveset( EEG, 'filename','Correct_epochs.set','filepath',out_path);
    [ALLEEG, EEG, CURRENTSET] = eeg_store(ALLEEG, EEG, CURRENTSET);
    

    %Save the labels and metadata associated with the epochs without errors
    epoch_labels_file = fullfile(out_path, 'Correct_labels.csv');
    fid = fopen(epoch_labels_file, 'w');
    fprintf(fid, 'Subject,Session,EpochIndex,EventType,EventPosition\n');

    for e = 1:length(EEG.epoch)
        ev_type = EEG.epoch(e).eventtype;        % solo un evento por epoch
        ev_pos  = EEG.epoch(e).eventposition;     % posición del evento
        fprintf(fid, '%s,%s,%d,%s,%d\n', ...
                subject_name, session_name, e, ev_type, ev_pos);
    end

    fclose(fid);
    fprintf('Etiquetas de epochs guardadas en: %s\n', epoch_labels_file);


end