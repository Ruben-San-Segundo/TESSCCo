global eeg

subjects = dir(fullfile(root_dir, 'Subject_*'));

for i = 1:length(subjects)
    %If the item is not a directory, continue
    if ~subjects(i).isdir
        continue
    end
    
    %obtain the path of a subject
    subject_path = fullfile(root_dir, subjects(i).name);
    subject_out_path = fullfile(out_dir, subjects(i).name);

    if ~isfolder(subject_out_path)
        mkdir(subject_out_path);
    end

    %We have two sessions
    for session_num = 1:n_sessions
        %Obtain the name and path to the session
        session_name = sprintf('Session_%02d', session_num);
        session_path = fullfile(subject_path, session_name);
        session_out_path = fullfile(subject_out_path, session_name);
        
        if ~isfolder(session_path)
            continue
        end
        
        %Creates the session folder
        if ~isfolder(session_out_path)
            mkdir(session_out_path);
        end
       

        %Obtain the path to the EEG.csv
        bbt_folders = dir(fullfile(session_path, 'BBT-E32*'));
        for j = 1:length(bbt_folders)
            if ~bbt_folders(j).isdir
                continue
            end
            bbt_path = fullfile(session_path, bbt_folders(j).name);
            
            %Defining EEG and epochs path
            fprintf('Processing %s\n', bbt_path);
            EEG_in_path = fullfile(bbt_path,'EEG.csv');
            epochs_path = fullfile(session_path, 'epoch_eeglab.txt');
            
            %Preprocess for that subject and session
            EEG_Preprocess_function(EEG_in_path,session_out_path ,loc_path,epochs_path,256);
            pause(5); 
        end
    end
end
