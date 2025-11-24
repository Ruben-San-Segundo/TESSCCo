%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SignificantChannels.m runs per-subject ERP statistics (1-way ANOVA / permutation testing) on an
% EEGLAB STUDY to identify electrodes that are consistently significant.
% Produces per-subject topoplots, a summary table of significant channels,
% recurrence histograms, and topographic visualizations of significance.
%
% Inputs:
%   - study_path    : folder where `Complete Native.study` is stored
%   - useDesign     : index of the STUDY design to test (e.g., 9)
%   - timeRange     : [tmin tmax] ms window for ERP/topoplot statistics
%   - pvalue        : numeric threshold or NaN (NaN returns exact p-values)
%   - correction    : 'none' or 'cluster' (FieldTrip correction)
%   - subject_list  : list of subject IDs to iterate (defaults shown in script)
%
% Outputs:
%   - Per-subject ERP topoplots (PNG)
%   - `pcond_summary.mat` and `pcond_summary.csv` (summary table of channel-level significance)
%   - Histogram of significant-channel recurrence (PNG)
%   - Topoplot images highlighting frequently significant channels (PNG)
%   - Global mean p-value topoplot (PNG)
%   - All files saved under: <out_path>/Significant_Channels/<DesignName>/<timeRange>/
%
% Steps:
%   1. Select the folders where the study is stored and where the results
%   will be stored
%   2. Setup the statistical parameters (minimun p-value, statistical test,
%   corrections, etc.)
%   3. Create a series of folders to save all the results.
%   SignificantChannels/StudyType/TimeRange (e.g.
%   SignificantChannels/Spanish ALL/-200_2000 ms)
%   4. Compute the statistical analysis saving individual results
%   5. Save summarys in graphics (such as most repeated significant
%   channels or p-value topographic plot)
%
% Dependencies:
%   - EEGLAB
%   - FieldTrip EEGLab plugin (for permutation testing)
%
% Author: Mario Lobo (UPM)
% Version: 12-11-2025
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Set up
clear; close all; clc;

study_path = 'C:\Users\user\Desktop\Mario Lobo\Silent Speech Data Amazon\3. Pre-processed';


%% Import Study


[ALLEEG EEG CURRENTSET ALLCOM] = eeglab;
[STUDY ALLEEG] = pop_loadstudy('filename', 'Complete Native.study', 'filepath', study_path);
CURRENTSTUDY = 1; EEG = ALLEEG; CURRENTSET = [1:length(EEG)];

%% Create the designs (RUN ONLY IF THE STUDY IS NEW AND NO CREATED WITH THE 'CREATE_STUDY' SCRIPT)

% % Spanish Designs
% STUDY = std_makedesign(STUDY, ALLEEG, 1, 'name','Spanish OS','delfiles','off','defaultdesign','off','variable1','type','values1',{'Apaga_FireTV_os','Baja_el_volumen_os','Enciende_la_televisión_os','Silencia_FireTV_os','Sube_el_volumen_os'},'vartype1','categorical','subjselect',{'01','02','03','04','05','06','07','08','09','10','11','12','13','14','15','16','17','18','19','20','21'});
% STUDY = std_makedesign(STUDY, ALLEEG, 2, 'name','Spanish CS','delfiles','off','defaultdesign','off','variable1','type','values1',{'Apaga_FireTV_cs','Baja_el_volumen_cs','Enciende_la_televisión_cs','Silencia_FireTV_cs','Sube_el_volumen_cs'},'vartype1','categorical','subjselect',{'01','02','03','04','05','06','07','08','09','10','11','12','13','14','15','16','17','18','19','20','21'});
% STUDY = std_makedesign(STUDY, ALLEEG, 3, 'name','Spanish ALL','delfiles','off','defaultdesign','off','variable1','type','values1',{'Apaga_FireTV_cs','Baja_el_volumen_cs','Enciende_la_televisión_cs','Silencia_FireTV_cs','Sube_el_volumen_cs','Apaga_FireTV_cs','Baja_el_volumen_cs','Enciende_la_televisión_cs','Silencia_FireTV_cs','Sube_el_volumen_cs'},'vartype1','categorical','subjselect',{'01','02','03','04','05','06','07','08','09','10','11','12','13','14','15','16','17','18','19','20','21'});
% % English designs
% STUDY = std_makedesign(STUDY, ALLEEG, 4, 'name','English OS','delfiles','off','defaultdesign','off','variable1','type','values1',{'Turn_down_volume_os','Turn_on_television_os','Turn_up_volume_os','Mute_FireTV_os','Turn_off_FireTV_os'},'vartype1','categorical','subjselect',{'01','02','03','04','05','06','07','08','09','10','11','12','13','14','15','16','17','18','19','20','21'});
% STUDY = std_makedesign(STUDY, ALLEEG, 5, 'name','English CS','delfiles','off','defaultdesign','off','variable1','type','values1',{'Turn_down_volume_cs','Turn_on_television_cs','Turn_up_volume_cs','Mute_FireTV_cs','Turn_off_FireTV_cs'},'vartype1','categorical','subjselect',{'01','02','03','04','05','06','07','08','09','10','11','12','13','14','15','16','17','18','19','20','21'});
% STUDY = std_makedesign(STUDY, ALLEEG, 6, 'name','English ALL','delfiles','off','defaultdesign','off','variable1','type','values1',{'Turn_down_volume_os','Turn_on_television_os','Turn_up_volume_os','Mute_FireTV_os','Turn_off_FireTV_os','Turn_down_volume_cs','Turn_on_television_cs','Turn_up_volume_cs','Mute_FireTV_cs','Turn_off_FireTV_cs'},'vartype1','categorical','subjselect',{'01','02','03','04','05','06','07','08','09','10','11','12','13','14','15','16','17','18','19','20','21'});
% % Spanish + English Designs
% STUDY = std_makedesign(STUDY, ALLEEG, 7, 'name','ALL OS','delfiles','off','defaultdesign','off','variable1','type','values1',{'Apaga_FireTV_os','Baja_el_volumen_os','Enciende_la_televisión_os','Silencia_FireTV_os','Sube_el_volumen_os','Turn_down_volume_os','Turn_on_television_os','Turn_up_volume_os','Mute_FireTV_os','Turn_off_FireTV_os'},'vartype1','categorical','subjselect',{'01','02','03','04','05','06','07','08','09','10','11','12','13','14','15','16','17','18','19','20','21'});
% STUDY = std_makedesign(STUDY, ALLEEG, 8, 'name','ALL CS','delfiles','off','defaultdesign','off','variable1','type','values1',{'Turn_down_volume_cs','Turn_on_television_cs','Turn_up_volume_cs','Mute_FireTV_cs','Turn_off_FireTV_cs','Apaga_FireTV_cs','Baja_el_volumen_cs','Enciende_la_televisión_cs','Silencia_FireTV_cs','Sube_el_volumen_cs'},'vartype1','categorical','subjselect',{'01','02','03','04','05','06','07','08','09','10','11','12','13','14','15','16','17','18','19','20','21'});
% STUDY = std_makedesign(STUDY, ALLEEG, 9, 'name','ALL','delfiles','off','defaultdesign','off','variable1','type','values1',{'Turn_down_volume_cs','Turn_on_television_cs','Turn_up_volume_cs','Mute_FireTV_cs','Turn_off_FireTV_cs','Apaga_FireTV_cs','Baja_el_volumen_cs','Enciende_la_televisión_cs','Silencia_FireTV_cs','Sube_el_volumen_cs','Apaga_FireTV_os','Baja_el_volumen_os','Enciende_la_televisión_os','Silencia_FireTV_os','Sube_el_volumen_os','Turn_down_volume_os','Turn_on_television_os','Turn_up_volume_os','Mute_FireTV_os','Turn_off_FireTV_os'},'vartype1','categorical','subjselect',{'01','02','03','04','05','06','07','08','09','10','11','12','13','14','15','16','17','18','19','20','21'});
% % Save study
% [STUDY EEG] = pop_savestudy( STUDY, EEG, 'savemode','resave');

%% Stats parameters Set-up
pvalue = NaN; % a number or NaN. NaN returns exact p-values. A number returns a binary mask
correction = 'none'; % 'none' or 'cluster'
STUDY = pop_statparams(STUDY, 'condstats','on','singletrials','on','mode','fieldtrip','fieldtripmethod','montecarlo','fieldtripalpha',pvalue,'fieldtripmcorrect',correction);

useDesign = 9;
timeRange = [-200 3000]; 

STUDY = pop_erpparams(STUDY, 'topotime',timeRange); 

%% Subjects, channels and times

subject_list = arrayfun(@(x) sprintf('%02d', x), 1:20, 'UniformOutput', false);

all_channels = {ALLEEG(1).chanlocs.labels};

timeLabel = sprintf('%d_%dms', timeRange(1), timeRange(2));

%% Set-up output variables and folders
%This will allow to save which channel is significant for each subject
significance_matrix = zeros(length(subject_list), length(all_channels));
out_path = "C:\Users\user\Desktop\Mario Lobo\Silent Speech Data Amazon\Study";
% Paths where to save all the results (Separated by design and time range)
output_dir = fullfile(out_path,'Significant_Channels',STUDY.design(useDesign).name, timeLabel);
if ~exist(output_dir, 'dir')
    mkdir(output_dir);
end

%% Main Loop for the 1-way ANOVA Permutation Testing

for i = 1:length(subject_list)
    % Iterate per subject
    subj = subject_list{i};
    fprintf('Processing subject %s...\n', subj);
    
    % Execute ERP analysis
    [STUDY, erpdata, erptimes, pgroup, pcond, pinter] = std_erpplot(STUDY, ALLEEG, ...
        'channels', all_channels, ...
        'subject', subj, ...
        'design', useDesign);
    
    % Extract the boolean values of the mask (i.e. significant electrodes)
    significance = double(pcond{1}(:));  % Convert to numeric vector
    significance_matrix(i, :) = significance';  % store as a row in the matrix
    
    % Save topographic figure
    fig_name = fullfile(output_dir, sprintf('ERP_Topoplot_Subject_%s.png', subj));
    saveas(gcf, fig_name);
    close(gcf);
    
    % Save individual results uncommenting next line
    % save(fullfile(output_dir, sprintf('ERP_subject_%s.mat', subj)),'erpdata', 'erptimes', 'pgroup', 'pcond', 'pinter');
end

% Create a table with labels
pcond_table = array2table(significance_matrix, ...
    'VariableNames', all_channels, ...
    'RowNames', subject_list);

% Save table and .csv
save(fullfile(output_dir, 'pcond_summary.mat'), 'pcond_table', 'significance_matrix');
writetable(pcond_table, fullfile(output_dir, 'pcond_summary.csv'), 'WriteRowNames', true);

disp('Analysis completed and results stored.');

%% Find the most significant channels
threshold = 0.05; % Threashold to count as significant (it should be the same as pvalue if pvalue is a number)

% Count how many times an electrode is marked as a significant
sig_count = sum(significance_matrix<threshold, 1);

figure('Name', 'Significant channels histogram', 'Color', 'w');
bar(sig_count);
xticks(1:length(all_channels));
xticklabels(all_channels);
xtickangle(45);
ylabel('Number of times significant');
title('Significant channels histogram');
grid on;
saveas(gcf, fullfile(output_dir, 'Histogram_Significant_Channels.png'));

%% Plot the topographic map with significant electrodes masked
% Threshold = number of times an electrode appears as significant
threshold = 7;
highlight_idx = find(sig_count >= threshold);

% Underline significant channels
base_values = zeros(1, length(ALLEEG(1).chanlocs));

figure('Name', 'Topoplot of most significant channels', 'Color', 'w');
topoplot(base_values, ALLEEG(1).chanlocs, ...
         'style', 'map', 'electrodes', 'ptslabels', ...
         'emarker2', {highlight_idx, 'o', 'r', 5, 1},'colormap', [1 1 1; 1 1 1]); % blanco y rojo); % círculo rojo

% Title and save the channels
title(sprintf('Channels that appear ≥%d times as significant', threshold));
saveas(gcf, fullfile(output_dir, 'Topoplot_Significant_Recurrence.png'));

disp('Summary of significance and topoplots correctly generated.');

%% Plot the topographic map with exact pvalues (if pvalue is NaN)
% With this approach, channels that only appears a few times as significant
% are attenuated
mean_significance = mean(significance_matrix,1);

% Create figure
figure('Name', 'Topographic map of global ERP significance', 'Color', 'w');

% Topoplot
topoplot(mean_significance, ALLEEG(1).chanlocs, ...
    'maplimits', [0 1], ...  % Escala completa de p-values
    'style', 'both', ...
    'electrodes', 'ptslabels');

% Red = low pvalue = significance, yellow = high p-value = low significance
colormap(hot); % "hot" invertido: rojo = bajo p, azul = alto p

% Colorbar
cb = colorbar;
ylabel(cb, 'Mean p-value (lower = more significant)');

% Title
title('Global ERP significance map (mean p-values across subjects)');

% Guardar la figura
saveas(gcf, fullfile(output_dir, 'Topoplot_Global_Mean_Exact_Significance.png'));
%% Plot the topographic map with interpolated significance (if pvalue is a number)

figure('Name', 'Continous map of recurrence', 'Color', 'w');
% Draw topoplot where values = number of times as significant
topoplot(sig_count, ALLEEG(1).chanlocs, ...
    'maplimits', [0 max(sig_count)], ...
    'style', 'both', ...
    'electrodes', 'ptslabels','emarker2', {highlight_idx, 'o', 'r', 10, 1});
colorbar;
title(sprintf('Mapa de recurrencia de significancia por canal (threshold = %d)',threshold));


% Save figure
saveas(gcf, fullfile(output_dir, 'Topoplot_Interpolated_Significance.png'));
