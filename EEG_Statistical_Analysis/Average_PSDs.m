%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Average_PSDs.m computes and plots averaged power spectral densities (PSDs) from a
% concatenated epochs matrix and its metadata. Supports grouping by
% condition, channel/session exclusions, and saves per-group PSD figures.
%
% Inputs / files (edit constants in the script):
%   - epochs mat file: variable `epochs` (nTrials x nSamples x nChannels)
%   - metadata CSV: per-epoch rows matching epochs
%
% Outputs:
%   - PNGs: Averaged PSD plots per group (saved under out_path_signals)
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
%   6. Indicate groups to compute PSDs separated
%   7. Average, normalize each channels
%   8. Compute the PSD for that averaged signal and store it in a variable
%   9. Average all the PSDs and obtain the standard deviation  
%   10. Plot the Averaged PSDs of all the trials and all the channels
%   11. Save the plot
%
% Key parameters to check:
%   - Fs, fmin, fmax
%   - window_length, noverlap, nfft for pwelch
%   - channel_labels must match nChannels
%   - group_by: {"Command","EventType","language","os_cs","all","none"}
%
% Dependencies:
%   - MATLAB Signal Processing Toolbox (pwelch)
%
% Author: Mario Lobo (UPM)
% Email:  mario.lobo.alonso@alumnos.upm.es
% Version: 12-11-2025
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%% --- Output folder ---
out_path_signals = "C:\Users\user\Desktop\Mario Lobo\Silent Speech Data Amazon\Study\PSDs\Signals";


if ~exist(out_path_signals, 'dir')
    mkdir(out_path_signals);
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

% --- Welch parameters ---
fmin = 1;
fmax = 100;
window_length = Fs; % 1 second window
noverlap = window_length / 2; %0.5s overlapping
nfft = 2^nextpow2(window_length);


%% --- Exclude channels and subject's sessions ---
% Name of channels to be excluded. Empty = no exclusions
%exclude_channels = {'P8','TP7'};  
exclude_channels = {}; 

% Pairs of Subject and session to be excluded. For example {'Subject_04', 'Session_02'; 'Subject_11','Session_01'};
% Usa pares {"SubjectID", "SessionID"}.
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


    % --- Average the epochs of the group per channel ---
    group_epochs = epochs(idx_group,:,:);
    mean_data = squeeze(mean(group_epochs,1));   % [nSamples x nChannels]

    n_trials = size(group_epochs,1); %info for plotting

    % --- Calculate average PSD from the averaged epochs ---
    psd_all = [];
    for ch = ch_include
        % Select first averaged channel
        x = mean_data(:,ch);

        % Calculate the PSD with Welch
        [Pxx, f] = pwelch(x, window_length, noverlap, nfft, Fs);
        idx = f >= fmin & f <= fmax;
        psd_all(:,ch) = Pxx(idx);
    end
    f_plot = f(idx);

    % --- Average the mean PSD with the standard deviation as well ---
    apsd_mean = mean(psd_all(:,ch_include), 2);
    apsd_std  = std(psd_all(:,ch_include), 0, 2);

    % --- Turn in logarithmic base ---
    apsd_mean_log = log10(apsd_mean);
    apsd_std_log  = log10(apsd_mean + apsd_std) - apsd_mean_log;

    % --- Plote one figure per group ---
    figure('Name', sprintf('PSD - %s: %s', group_by, group_value), 'NumberTitle', 'off');
    hold on;

    % --- Shadow the standard deviation ---
    x_patch = [f_plot; flipud(f_plot)];
    y_patch = [apsd_mean_log + apsd_std_log; flipud(apsd_mean_log - apsd_std_log)];
    fill(x_patch, y_patch, [0.8 0.8 1], 'EdgeColor', 'none');

    % --- Draw APSD ---
    plot(f_plot, apsd_mean_log, 'b', 'LineWidth', 1.8);


    % --- Plot info ---
    xlabel('Frecuencia (Hz)');
    ylabel('PSD (log_{10}) uV^2/Hz');
    title(sprintf('Averaged PSD (%s = %s) — %d trials', group_by, group_value, n_trials), 'Interpreter', 'none');
    xlim([fmin fmax]);
    grid on;
    hold off;

     % --- Save figure ---
    %saveas(gcf, fullfile(out_path_signals,sprintf('AverageERP_%s-%s.png', group_by, group_value)));

end
