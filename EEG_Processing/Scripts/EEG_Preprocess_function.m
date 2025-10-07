function EEG_Preprocess_function(EEG_in_path, out_path,loc_path,epochs_path, fs)
%EEG_Preprocess_function preprocess the EEG in a .csv indicated in
%EEG_in_path. It also obtains the epochs indicated in epoch_path and
%saves a .csv with the preprocessed data and a .mat with the epochs
%separated in a 3D array.
%
%   Input parameters:
%     EEG_in_path - path to a .csv with the EEG data (Directly from
%     BitBrain)
%     out_path - path where the preprocessed .csv and the epochs .mat will
%     be stored
%     loc_path - path to the locs file with the electrodes locations
%     epochs_path - path to the epoch.txt file for EEGLab epoch extraction
%     for the indicated EEG.csv
%     fs - sampling rate of the EEG
%

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
    
    %Clear the table as we have everything in different variables
    clear("csv");
    
    % EEGLAB start
    [ALLEEG EEG CURRENTSET ALLCOM] = eeglab;
    
    %Importing the data into eeglab
    EEG = pop_importdata('dataformat','array','nbchan',0,'data','eeg','srate',fs,'pnts',0,'xmin',0,'chanlocs',loc_path);
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 0,'setname','RAW_data','gui','off'); 


    % Filter data
    %High-pass filter (FIR filter, order auto-selected)
    EEG = pop_eegfiltnew(EEG, 'locutoff',0.5,'plotfreqz',0);
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'setname','high-passed','overwrite','on','gui','off');

    %Notch filter 50Hz (FIR filter, order auto-selected)
    EEG = pop_eegfiltnew(EEG, 'locutoff',49,'hicutoff',51,'revfilt',1,'plotfreqz',0);
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'setname','hp+notch','overwrite','on','gui','off'); 


    %Re-referencing
    EEG = pop_reref( EEG, []);
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'overwrite','on','gui','off'); 
    
    % Segment reconstruction
    EEG = pop_clean_rawdata(EEG, 'FlatlineCriterion','off','ChannelCriterion','off','LineNoiseCriterion','off','Highpass','off','BurstCriterion',25,'WindowCriterion','off','BurstRejection','off','Distance','Euclidian');
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'setname','rejected','overwrite','on','gui','off'); 


    % It seems irrelevant to use this before or after ICA. We put it after
    % the rest of the pre-process because re-referencing and noise removal
    % with clean_raw_data might help. If the noise continues, it is time for
    % further action
    EEG = FrequencyArtifactRemovalV2(EEG, fs,80.5,2,5,1, false,1);
    % Saving new dataset
    [ALLEEG, EEG, CURRENTSET] = pop_newset(ALLEEG, EEG, 1, 'setname','extra-notch','overwrite','on','gui','off');

    % Other possibility is just to do:
    %EEG = pop_eegfiltnew(EEG, 'locutoff',78.5,'hicutoff',81.5,'revfilt',1,'plotfreqz',0);
    %[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'setname','extra-notch','overwrite','on','gui','off'); 


    % Independent Component Analysis
    % Extract ICA components (default from eeglab)
    EEG = pop_runica(EEG, 'icatype', 'runica', 'extended',1,'rndreset','yes','interrupt','on');
    [ALLEEG, EEG, CURRENTSET] = eeg_store(ALLEEG, EEG, CURRENTSET);

    % Label components with probability of being noise
    EEG = pop_iclabel(EEG, 'default');
    [ALLEEG, EEG, CURRENTSET] = eeg_store(ALLEEG, EEG, CURRENTSET);

    % See the components classification
    % pop_viewprops( EEG, 0, [], {'freqrange', [1 128]}, {}, 1, 'ICLabel' );

    %Flag components related to EOG as noise (if probability between 0.7 and 1)
    EEG = pop_icflag(EEG, [NaN NaN;NaN NaN;0.6 1;NaN NaN;NaN NaN;NaN NaN;NaN NaN]);
    [ALLEEG, EEG, CURRENTSET] = eeg_store(ALLEEG, EEG, CURRENTSET);

    %Remove components marked as noise
    %Array [] empty removes the components flagged as noise. If we add values,
    %then it will remove the indicated components
    %It will not ask for confirmation (the 0 indicated)
    EEG = pop_subcomp( EEG, [], 0);
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'setname','ICAed','overwrite','on','gui','off');



    % Extract Epochs

    %saving the complete EEG data
    complete_EEG = EEG.data';

    %Import the epoch file
    EEG = pop_importevent( EEG, 'event',epochs_path,'fields',{'latency','type','position'},'skipline',1,'timeunit',1e-06);
    [ALLEEG, EEG, CURRENTSET] = eeg_store(ALLEEG, EEG, CURRENTSET);

    %Extract the epochs
    EEG = pop_epoch( EEG, { 'Baja_el_volumen_os','Sube_el_volumen_os', 'Silencia_FireTV_os', 'Enciende_la_televisión_os', 'Apaga_FireTV_os', 'Turn_down_volume_os','Turn_up_volume_os', 'Mute_FireTV_os', 'Turn_on_television_os', 'Turn_off_FireTV_os','Baja_el_volumen_cs','Sube_el_volumen_cs', 'Silencia_FireTV_cs', 'Enciende_la_televisión_cs', 'Apaga_FireTV_cs', 'Turn_down_volume_cs','Turn_up_volume_cs', 'Mute_FireTV_cs', 'Turn_on_television_cs', 'Turn_off_FireTV_cs'  }, [-2  3], 'newname', 'Epochs', 'epochinfo', 'yes');
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'overwrite','on','gui','off'); 

    %If any event or epoch could not be extracted, or if different events aim to the same epoch, creates an
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


    %Save the dataset with everything
    EEG = pop_saveset( EEG, 'filename','Dataset_complete.set','filepath',out_path);
    [ALLEEG, EEG, CURRENTSET] = eeg_store(ALLEEG, EEG, CURRENTSET);

    %Discart epochs that might have multiple events associated
    EEG.epoch(not_used) = [];
    EEG.data(:,:,not_used) = [];


    % Saving the labels
    writelines(labels,fullfile(out_path,"correct_labels.txt"))


    %Save the steady timestamps and filtered data into a table with headers
    exit_csv = array2table([string(steady_timestamps) complete_EEG]);
    exit_csv.Properties.VariableNames = (["steady_timestamp" string({EEG.chanlocs.labels})]);

    % Export table
    writetable(exit_csv, append(out_path, '\EEG.csv'), "QuoteStrings","none");


    %Save a .mat with the separated epochs in a 3D array. This epochs match
    %the correct_epochs labels
    epochs = EEG.data;
    save(append(out_path, '\epochs.mat'),"epochs")

    %Save the Dataset without the bad epochs and events
    EEG = pop_saveset( EEG, 'filename','Dataset_correct.set','filepath',out_path);
    [ALLEEG, EEG, CURRENTSET] = eeg_store(ALLEEG, EEG, CURRENTSET);

end