%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% TFSignificance.m computes and summarizes time–frequency (TF) significance maps per subject
% (using STUDY ERSP statistics) for a chosen electrode and design. The
% script runs per-subject ERSP permutation tests, collects binary TF masks,
% and produces averaged significance maps, per-subject TF figures and
% saved TF-mask matrices for downstream analysis.
%
% Inputs:
%   - study_path : path containing the saved STUDY (.study)
%   - useDesign  : STUDY design index to test (e.g., 9)
%   - timeRange  : [tmin tmax] ms window for ERSP statistics
%   - channel    : cell with one channel label to analyze (e.g., {'CP5'})
%   - subject_list : list of subject IDs to iterate (default created in script)
%   - pvalue/correction set via pop_statparams (script sets fieldtrip/cluster by default)
%
% Outputs:
%   - Per-subject ERSP TF map PNGs
%   - signficance_matrix (nfreq x ntime x nSubjects) saved as 'significances.mat'
%   - Mean significance TF image (PNG)
%   - All outputs saved to: <out_path>/Significant_TFMaps/<DesignName>/<Channel>/<timeLabel>/
%
% Steps:
%   1. Select the folders where the study is stored and where the results
%   will be stored
%   2. Setup the statistical parameters (minimun p-value, statistical test,
%   corrections, etc.)
%   3. Create a series of folders to save all the results.
%   Significan_TFMaps/StudyType/Channel/TimeRange (e.g.
%   Significan_TFMaps/Spanish ALL/FC5/-200_2000 ms)
%   4. Compute the statistical analysis saving individual results
%   5. Save summarys in a graphic with the average significance
%
% Dependencies:
%   - EEGLAB
%   - FieldTrip EEGLab plugin
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

% %% Create the designs (RUN ONLY IF THE STUDY IS NEW)
% 
% % Spanish Designs
% STUDY = std_makedesign(STUDY, ALLEEG, 1, 'name','Spanish OS','delfiles','off','defaultdesign','off','variable1','type','values1',{'Apaga_FireTV_os','Baja_el_volumen_os','Enciende_la_televisión_os','Silencia_FireTV_os','Sube_el_volumen_os'},'vartype1','categorical','subjselect',{'01','02','03','04','05','06','07','08','09','10','11','12','13','14','15','16','17','18','19','20'});
% STUDY = std_makedesign(STUDY, ALLEEG, 2, 'name','Spanish CS','delfiles','off','defaultdesign','off','variable1','type','values1',{'Apaga_FireTV_cs','Baja_el_volumen_cs','Enciende_la_televisión_cs','Silencia_FireTV_cs','Sube_el_volumen_cs'},'vartype1','categorical','subjselect',{'01','02','03','04','05','06','07','08','09','10','11','12','13','14','15','16','17','18','19','20'});
% STUDY = std_makedesign(STUDY, ALLEEG, 3, 'name','Spanish ALL','delfiles','off','defaultdesign','off','variable1','type','values1',{'Apaga_FireTV_cs','Baja_el_volumen_cs','Enciende_la_televisión_cs','Silencia_FireTV_cs','Sube_el_volumen_cs','Apaga_FireTV_cs','Baja_el_volumen_cs','Enciende_la_televisión_cs','Silencia_FireTV_cs','Sube_el_volumen_cs'},'vartype1','categorical','subjselect',{'01','02','03','04','05','06','07','08','09','10','11','12','13','14','15','16','17','18','19','20'});
% % English designs
% STUDY = std_makedesign(STUDY, ALLEEG, 4, 'name','English OS','delfiles','off','defaultdesign','off','variable1','type','values1',{'Turn_down_volume_os','Turn_on_television_os','Turn_up_volume_os','Mute_FireTV_os','Turn_off_FireTV_os'},'vartype1','categorical','subjselect',{'01','02','03','04','05','06','07','08','09','10','11','12','13','14','15','16','17','18','19','20'});
% STUDY = std_makedesign(STUDY, ALLEEG, 5, 'name','English CS','delfiles','off','defaultdesign','off','variable1','type','values1',{'Turn_down_volume_cs','Turn_on_television_cs','Turn_up_volume_cs','Mute_FireTV_cs','Turn_off_FireTV_cs'},'vartype1','categorical','subjselect',{'01','02','03','04','05','06','07','08','09','10','11','12','13','14','15','16','17','18','19','20'});
% STUDY = std_makedesign(STUDY, ALLEEG, 6, 'name','English ALL','delfiles','off','defaultdesign','off','variable1','type','values1',{'Turn_down_volume_os','Turn_on_television_os','Turn_up_volume_os','Mute_FireTV_os','Turn_off_FireTV_os','Turn_down_volume_cs','Turn_on_television_cs','Turn_up_volume_cs','Mute_FireTV_cs','Turn_off_FireTV_cs'},'vartype1','categorical','subjselect',{'01','02','03','04','05','06','07','08','09','10','11','12','13','14','15','16','17','18','19','20'});
% % Spanish + English Designs
% STUDY = std_makedesign(STUDY, ALLEEG, 7, 'name','ALL OS','delfiles','off','defaultdesign','off','variable1','type','values1',{'Apaga_FireTV_os','Baja_el_volumen_os','Enciende_la_televisión_os','Silencia_FireTV_os','Sube_el_volumen_os','Turn_down_volume_os','Turn_on_television_os','Turn_up_volume_os','Mute_FireTV_os','Turn_off_FireTV_os'},'vartype1','categorical','subjselect',{'01','02','03','04','05','06','07','08','09','10','11','12','13','14','15','16','17','18','19','20'});
% STUDY = std_makedesign(STUDY, ALLEEG, 8, 'name','ALL CS','delfiles','off','defaultdesign','off','variable1','type','values1',{'Turn_down_volume_cs','Turn_on_television_cs','Turn_up_volume_cs','Mute_FireTV_cs','Turn_off_FireTV_cs','Apaga_FireTV_cs','Baja_el_volumen_cs','Enciende_la_televisión_cs','Silencia_FireTV_cs','Sube_el_volumen_cs'},'vartype1','categorical','subjselect',{'01','02','03','04','05','06','07','08','09','10','11','12','13','14','15','16','17','18','19','20'});
% STUDY = std_makedesign(STUDY, ALLEEG, 9, 'name','ALL','delfiles','off','defaultdesign','off','variable1','type','values1',{'Turn_down_volume_cs','Turn_on_television_cs','Turn_up_volume_cs','Mute_FireTV_cs','Turn_off_FireTV_cs','Apaga_FireTV_cs','Baja_el_volumen_cs','Enciende_la_televisión_cs','Silencia_FireTV_cs','Sube_el_volumen_cs','Apaga_FireTV_os','Baja_el_volumen_os','Enciende_la_televisión_os','Silencia_FireTV_os','Sube_el_volumen_os','Turn_down_volume_os','Turn_on_television_os','Turn_up_volume_os','Mute_FireTV_os','Turn_off_FireTV_os'},'vartype1','categorical','subjselect',{'01','02','03','04','05','06','07','08','09','10','11','12','13','14','15','16','17','18','19','20'});
% % Save study
% [STUDY EEG] = pop_savestudy( STUDY, EEG, 'savemode','resave');

%% Stats parameters Set-up
pvalue = 0.05; % a number or NaN. NaN returns exact p-values. A number returns a binary mask
correction = 'cluster'; % 'none' or 'cluster'
STUDY = pop_statparams(STUDY, 'condstats','on','singletrials','on','mode','fieldtrip','fieldtripmethod','montecarlo','fieldtripalpha',pvalue,'fieldtripmcorrect',correction);

useDesign = 9;

timeRange = [-200 2000];

STUDY = pop_erspparams(STUDY, 'timerange',timeRange, 'freqrange',[1 70]);% The longer the range, the bigger the variability

%% Subjects and channels
subject_list = arrayfun(@(x) sprintf('%02d', x), 1:20, 'UniformOutput', false);

% Change to select the channel (typically, a significant channel)
channel = {'CP5'};

timeLabel = sprintf('%d_%dms', timeRange(1), timeRange(2));


%% Set-up output folders

% Paths where to save all the results (Separated by design and channel)
output_dir = fullfile('C:\Users\user\Desktop\Mario Lobo\Silent Speech Data Amazon\Study','Significant_TFMaps',STUDY.design(useDesign).name,channel{1}, timeLabel);
if ~exist(output_dir, 'dir')
    mkdir(output_dir);
end

%% Main Loop for the 1-way ANOVA Permutation Testing

% Initiate variables to find dimensions once
first_subj = true;


for i = 1:length(subject_list)
    subj = subject_list{i};
    % Iterate per subject
    fprintf('Processing subject %s...\n', subj);
    
    % Execute ERSP Analysis
    [STUDY, erspdata, ersptimes, erspfreqs, pgroup, pcond, pinter] = std_erspplot(STUDY, ALLEEG, ...
        'channels',channel, 'subject', subj, 'design', useDesign);

    % Verify and extract the boolean values of the mask (i.e. significant Time-Frequency Regions)
    if ~isempty(pcond) && iscell(pcond) && ~isempty(pcond{1,1})
        significance = double(pcond{1,1});  % Matrix frec x tiempo (1 = significant)
        
        if first_subj
            % Create 3D Matrix: frec × time × subject
            [nfreq, ntime] = size(significance);
            significance_matrix = zeros(nfreq, ntime, length(subject_list));
            first_subj = false;
        end
        
        significance_matrix(:,:,i) = significance; % concatenar en la 3a dimensión
    else
        warning('pcond empty for subject %s', subj);
    end
    
    % Save plot
    fig_name = fullfile(output_dir, sprintf('ERSP_TFmap_Subject_%s_Ch_%s.png', subj,channel{1}));
    saveas(gcf, fig_name);
    close(gcf);
    
end

% Save table and .csv
save(fullfile(output_dir, 'significances.mat'), 'significance_matrix', 'ersptimes', 'erspfreqs', 'subject_list', 'channel');

disp('Analysis completed and results stored.');


%% Calcular y visualizar la significancia media
% Calculate the mean significance for each TF region between all the
% subjects
mean_mask = mean(significance_matrix, 3);

% plot the image
figure('Color','w');
imagesc(ersptimes, erspfreqs, mean_mask);

% Visual settings
axis xy;
xlabel('Time (ms)');
ylabel('Frecuency (Hz)');
title(sprintf('Average Significance (%s)', channel{1}));
colorbar;
colormap(jet);
caxis([0 1]); % 0 = none, 1 = significant for all the subjects

% Save figure
fig_name_mean = fullfile(output_dir, sprintf('Significancia_media_%s.png', channel{1}));
saveas(gcf, fig_name_mean);