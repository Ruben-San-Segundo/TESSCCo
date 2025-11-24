%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Average_ERPs.m computes and plots group or condition Average ERPs from a concatenated
% 3D epochs array and its metadata table. Produces per-group ERP time-series
% plots and EEGLAB topographic (topoplot) images.
%
% Inputs / files (edit constants in the script):
%   - epochs mat file: contains variable `epochs` (nTrials x nSamples x nChannels)
%   - metadata CSV: per-epoch rows matching epochs (same order)
%   - loc_path: EEGLAB .locs file for topographies
%
% Outputs:
%   - PNGs: Average ERP plots per group (signals)
%   - PNGs: Topographic maps per group (topo)
%   - Console summary of included trials and any warnings
%
% Steps:
%   1. Select the path where the 3D array with all the epochs is stored
%   2. Select the path where the information for each epoch is stored
%   3. Set up parameters (sampling rate, number of samples, number and name
%   of channels, etc.)
%   4. Set-up exclusions (for example, outlier channels or subject's
%   sesisons we know they are bad recorded)
%   5. Filter channels, epochs and metadata with information from step 4
%   6. Indicate groups to compute ERPs separated
%   7. Average, normalize, smooth, and plot each channel
%   8. Create the topographic plots of the Averaged ERPs in a series of
%   times
%
% Key parameters you may change:
%   - Fs (sampling rate), t (time vector in ms)
%   - channel_labels (must match nChannels)
%   - exclude_channels, exclude_subject_session
%   - group_by: "none"/"all" or one of {"Command","EventType","language","os_cs"}
%   - SGolay smoothing (sgolay_order, sgolay_frame)
%   - time_points for topoplot
%
% Dependencies:
%   - EEGLAB
%   - Signal Processing Toolbox (sgolayfilt) or equivalent
%
% Author: Mario Lobo (UPM)
% Email:  mario.lobo.alonso@alumnos.upm.es
% Version: 28-10-2025
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%% --- Output folder ---
out_path_signals = "C:\Users\user\Desktop\Mario Lobo\Silent Speech Data Amazon\Study\ERPs\Signals";
out_path_topo = "C:\Users\user\Desktop\Mario Lobo\Silent Speech Data Amazon\Study\ERPs\Topo";

if ~exist(out_path_signals, 'dir')
    mkdir(out_path_signals);
end

if ~exist(out_path_topo, 'dir')
    mkdir(out_path_topo);
end


%% --- Load EEG matrix ---
load("C:\Users\user\Desktop\Mario Lobo\Silent Speech Data Amazon\3. Pre-processed\Clean_concatenated_epochs.mat");
% epochs: [nTrials x nSamples x nChannels]

%% --- Load metadata ---
metadata = readtable("C:\Users\user\Desktop\Mario Lobo\Silent Speech Data Amazon\3. Pre-processed\Clean_concatenated_labels.csv");
% Expected columns: Subject, Session, EpochIndex, EventType, EventPosition, language, os_cs, Command

if height(metadata) ~= size(epochs,1)
    error('Number of metadata rows and number of epochs is not the same');
end

%% --- Set-up parameters ---
Fs = 256;                     
n_samples = size(epochs,2);
n_channels = size(epochs,3);
t = linspace(-2000, 3000, n_samples);   % Vector de tiempo (ms)



% Channel labels (32 channels, in order)
channel_labels = {'Fp1','Fpz','Fp2','F7','F5','F3','Fz','F4','F8', ...
                  'FC5','FC3','FC1','FC2','FC6','T7','C3','C1','Cz','C2','C4','T8', ...
                  'TP7','CP5','CP3','CPz','CP4','TP8','P7','P3','P4','P8','POz'};

if numel(channel_labels) ~= n_channels
    warning('Number of labels doesnt coincide with n_channels (%d vs %d)', numel(channel_labels), n_channels);
end

% --- Parámetros de suavizado ---
sgolay_order = 3;     
sgolay_frame = 21;    % debe ser impar

%% --- Exclude channels and subject's sessions ---
% Name of channels to be excluded. Empty = no exclusions
% exclude_channels = {'Fp1','Fpz','Fp2','F7','F5','F3','Fz','F4','F8', ...
%                  'FC5','FC3','FC1','FC2','FC6','T7','C3','C1','Cz','C2','C4','T8', ...
%                  'TP7','CP5','CP3','CP4','TP8','P7','P8'};  
exclude_channels = {}; 

% Pairs of Subject and session to be excluded. For example {'Subject_04', 'Session_02'; 'Subject_11','Session_01'};
% Usa pares {"SubjectID", "SessionID"}.
%exclude_subject_session = {'Subject_04', 'Session_02';};
exclude_subject_session = {};

% --- Find excluded channel index ---
[~, ch_exclude_idx] = intersect(channel_labels, exclude_channels);
ch_exclude_idx = unique([ch_exclude_idx]);  % mantener exclusión fija
ch_include = setdiff(1:n_channels, ch_exclude_idx);

%% --- Filter metadata and epochs following the exclusions above presented ---

include_idx = true(height(metadata),1);

% Create the mask
for i = 1:size(exclude_subject_session,1)
    subj = exclude_subject_session{i,1};
    sess = exclude_subject_session{i,2};
    mask = strcmp(metadata.Subject, subj) & strcmp(metadata.Session, sess);
    include_idx = include_idx & ~mask;
end

% Apply the filter
epochs = epochs(include_idx,:,:);
metadata = metadata(include_idx,:);

fprintf("%d trials included after applying subject-session exclussions.\n", size(epochs,1));

%% --- Select groups ---
% none or all = all the epochs together
% os_cs = compare between overt speech and covert speech averaged ERPs
% Command = compare between sentences without taking os_cs into account
% language = compare english sentences with spanish sentences
% EventType = compare the sentences taking os and cs into account

group_by = "none";  % <-- puede ser "Command", "EventType", "language", "os_cs", "all" o "none"

if ismember(lower(string(group_by)), ["all", "none"])
    unique_groups = {"All Trials"};
    metadata.GroupingColumn = repmat(unique_groups, height(metadata), 1);
    group_field = "GroupingColumn";
else
    group_field = group_by;
    unique_groups = unique(metadata.(group_field));
end

fprintf("Grouping ERPs byr %s (%d groups found)\n", group_by, numel(unique_groups));



%% --- Iterate ERP for each group ---
for g = 1:numel(unique_groups)
    % --- Select group ---
    group_value = unique_groups{g};
    
    % --- Obtain indexes of the group ---
    if ismember(lower(string(group_by)), ["all", "none"])
        idx_group = true(size(epochs,1),1);
    else
        idx_group = strcmp(metadata.(group_field), group_value);
    end

    group_epochs = epochs(idx_group,:,:);


    % --- Baseline correction ---
    % Define baseline interval (e.g. from -200 ms to 0 ms)
    baseline_window = [-400 0]; 
    baseline_idx = t >= baseline_window(1) & t <= baseline_window(2);

    % Preallocate corrected epochs
    corrected_epochs = zeros(size(group_epochs));

    for e = 1:size(group_epochs, 1)
        epoch_data = squeeze(group_epochs(e,:,:));  % [nSamples x nChannels]

        % Compute mean baseline value per channel
        baseline_mean = mean(epoch_data(baseline_idx, :), 1);

        % Subtract baseline mean from entire epoch
        epoch_corrected = epoch_data - baseline_mean;


        corrected_epochs(e,:,:) = epoch_corrected;
    end


    % --- Average the epochs of the group ---
    mean_data = squeeze(mean(corrected_epochs,1));   % [nSamples x nChannels]
    
    %mean_norm = zscore(mean_data);

    % --- Center and normalize that averaged signal ---
    %mean_centered = mean_data - mean(mean_data);
    %mean_norm = mean_centered ./ max(abs(mean_centered));

    % --- Smooth using a SGolay filter ---
    mean_smooth = sgolayfilt(double(mean_data), sgolay_order, sgolay_frame);

    % --- Figure per group ---
    figure('Name', sprintf('ERP - %s: %s', group_by, group_value), 'NumberTitle', 'off');
    hold on;
    
    % --- Draw all non excluded channels ---
    for ch = ch_include
        plot(t, mean_smooth(:, ch), 'LineWidth', 1.2, 'DisplayName', channel_labels{ch});
    end

    % --- Draw the mean ERP across all non excluded channels ---
    %mean_across_channels = mean(mean_smooth(:, ch_include), 2);
    %plot(t, mean_across_channels, 'k', 'LineWidth', 2.5, 'DisplayName', 'Mean ERP');

    % --- Plot info ---
    xlabel('Time (ms)');
    ylabel('Amplitude (uV)');
    title(sprintf('Average ERP (%s = %s)', group_by, group_value), 'Interpreter', 'none');
    xline(-1700, '--r', 'LineWidth', 1);
    xline(300, '--r', 'LineWidth', 1);
    grid on;
    legend('show', 'Location', 'eastoutside');
   
    hold off;

    % Save figure
    saveas(gcf, fullfile(out_path_signals,sprintf('AverageERP_%s_%s.png', group_by, group_value)));



end

%% --- Generate topografic maps in EEGLab for the Average ERPs ---

% timepoints in ms to be plotted
time_points = [0 100 200 300 400 500 600 700 800 900 1100 1300 1500 1700 1900 2100 2200 2300 2400 2500 2600 2700 2800 2900 3000 3100 3200 3300 3500 3700 3900 4100 4300 4500 4700 4900];

% General info of the data
fs = 256;
loc_path = "C:\Users\user\Desktop\AMAZON_BCI\Code\Amazon_SSI\EEG_Processing\Scripts\BitBrain_SSI_placement.loc";

% Iterate for each group
for g = 1:numel(unique_groups)
    % Obtain the group
    group_value = unique_groups{g};

    % Obtain the indexes of each group member
    if ismember(lower(string(group_by)), ["all", "none"])
        idx_group = true(size(epochs,1),1);
    else
        idx_group = strcmp(metadata.(group_field), group_value);
    end


     group_epochs = epochs(idx_group,:,:);


    % --- Baseline correction ---
    % Define baseline interval (e.g. from -200 ms to 0 ms)
    baseline_window = [-400 0]; 
    baseline_idx = t >= baseline_window(1) & t <= baseline_window(2);

    % Preallocate corrected epochs
    corrected_epochs = zeros(size(group_epochs));

    for e = 1:size(group_epochs, 1)
        epoch_data = squeeze(group_epochs(e,:,:));  % [nSamples x nChannels]

        % Compute mean baseline value per channel
        baseline_mean = mean(epoch_data(baseline_idx, :), 1);

        % Subtract baseline mean from entire epoch
        epoch_corrected = epoch_data - baseline_mean;


        corrected_epochs(e,:,:) = epoch_corrected;
    end


    % --- Average the epochs of the group ---
    mean_data = squeeze(mean(corrected_epochs,1));   % [nSamples x nChannels]


    % Obtain the Average ERP for the group (same as before)
    mean_data = squeeze(mean(group_epochs,1));   % [nSamples x nChannels]
    %mean_centered = mean_data - mean(mean_data);
    %mean_norm = mean_centered ./ max(abs(mean_centered));


    mean_smooth = sgolayfilt(double(mean_data), sgolay_order, sgolay_frame);

    % Import the mean_smooth to EEGLab
    % EEGLAB start
    [ALLEEG EEG CURRENTSET ALLCOM] = eeglab;

    % Transpose (we need channels x samples)
    eeg = mean_smooth';


    %Importing the data into eeglab
    EEG = pop_importdata('dataformat','array','nbchan',size(eeg,1),'data','eeg','srate',fs,'pnts',size(eeg,2),'xmin',0,'chanlocs',char(loc_path));
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 0,'setname','Average ERP','gui','off'); 


    % Plot the topographic maps. 
    pop_topoplot(EEG, 1, time_points ,sprintf('ERP Topoplots - %s: %s', group_by, group_value),[6 6] ,0,'electrodes','on')


    % Guardar figura
    saveas(gcf, fullfile(out_path_topo,sprintf('Topo_%s_%s.png', group_by, group_value)));

end
