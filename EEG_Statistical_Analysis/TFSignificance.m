%% Import Study
[ALLEEG EEG CURRENTSET ALLCOM] = eeglab;
[STUDY ALLEEG] = pop_loadstudy('filename', 'Complete Native Study.study', 'filepath', 'C:\Users\user\Desktop\Mario Lobo\Silent Speech Data Amazon\Study');
CURRENTSTUDY = 1; EEG = ALLEEG; CURRENTSET = [1:length(EEG)];

%% Create the designs (RUN ONLY IF THE STUDY IS NEW)

% Spanish Designs
STUDY = std_makedesign(STUDY, ALLEEG, 1, 'name','Spanish OS','delfiles','off','defaultdesign','off','variable1','type','values1',{'Apaga_FireTV_os','Baja_el_volumen_os','Enciende_la_televisión_os','Silencia_FireTV_os','Sube_el_volumen_os'},'vartype1','categorical','subjselect',{'01','02','03','04','05','06','07','08','10','11','12','13','14','15','16','17','18','19','20'});
STUDY = std_makedesign(STUDY, ALLEEG, 2, 'name','Spanish CS','delfiles','off','defaultdesign','off','variable1','type','values1',{'Apaga_FireTV_cs','Baja_el_volumen_cs','Enciende_la_televisión_cs','Silencia_FireTV_cs','Sube_el_volumen_cs'},'vartype1','categorical','subjselect',{'01','02','03','04','05','06','07','08','10','11','12','13','14','15','16','17','18','19','20'});
STUDY = std_makedesign(STUDY, ALLEEG, 3, 'name','Spanish ALL','delfiles','off','defaultdesign','off','variable1','type','values1',{'Apaga_FireTV_cs','Baja_el_volumen_cs','Enciende_la_televisión_cs','Silencia_FireTV_cs','Sube_el_volumen_cs','Apaga_FireTV_cs','Baja_el_volumen_cs','Enciende_la_televisión_cs','Silencia_FireTV_cs','Sube_el_volumen_cs'},'vartype1','categorical','subjselect',{'01','02','03','04','05','06','07','08','10','11','12','13','14','15','16','17','18','19','20'});
% English designs
STUDY = std_makedesign(STUDY, ALLEEG, 4, 'name','English OS','delfiles','off','defaultdesign','off','variable1','type','values1',{'Turn_down_volume_os','Turn_on_television_os','Turn_up_volume_os','Mute_FireTV_os','Turn_off_FireTV_os'},'vartype1','categorical','subjselect',{'01','02','03','04','05','06','07','08','10','11','12','13','14','15','16','17','18','19','20'});
STUDY = std_makedesign(STUDY, ALLEEG, 5, 'name','English CS','delfiles','off','defaultdesign','off','variable1','type','values1',{'Turn_down_volume_cs','Turn_on_television_cs','Turn_up_volume_cs','Mute_FireTV_cs','Turn_off_FireTV_cs'},'vartype1','categorical','subjselect',{'01','02','03','04','05','06','07','08','10','11','12','13','14','15','16','17','18','19','20'});
STUDY = std_makedesign(STUDY, ALLEEG, 6, 'name','English ALL','delfiles','off','defaultdesign','off','variable1','type','values1',{'Turn_down_volume_os','Turn_on_television_os','Turn_up_volume_os','Mute_FireTV_os','Turn_off_FireTV_os','Turn_down_volume_cs','Turn_on_television_cs','Turn_up_volume_cs','Mute_FireTV_cs','Turn_off_FireTV_cs'},'vartype1','categorical','subjselect',{'01','02','03','04','05','06','07','08','10','11','12','13','14','15','16','17','18','19','20'});
% Spanish + English Designs
STUDY = std_makedesign(STUDY, ALLEEG, 7, 'name','ALL OS','delfiles','off','defaultdesign','off','variable1','type','values1',{'Apaga_FireTV_os','Baja_el_volumen_os','Enciende_la_televisión_os','Silencia_FireTV_os','Sube_el_volumen_os','Turn_down_volume_os','Turn_on_television_os','Turn_up_volume_os','Mute_FireTV_os','Turn_off_FireTV_os'},'vartype1','categorical','subjselect',{'01','02','03','04','05','06','07','08','10','11','12','13','14','15','16','17','18','19','20'});
STUDY = std_makedesign(STUDY, ALLEEG, 8, 'name','ALL CS','delfiles','off','defaultdesign','off','variable1','type','values1',{'Turn_down_volume_cs','Turn_on_television_cs','Turn_up_volume_cs','Mute_FireTV_cs','Turn_off_FireTV_cs','Apaga_FireTV_cs','Baja_el_volumen_cs','Enciende_la_televisión_cs','Silencia_FireTV_cs','Sube_el_volumen_cs'},'vartype1','categorical','subjselect',{'01','02','03','04','05','06','07','08','10','11','12','13','14','15','16','17','18','19','20'});
STUDY = std_makedesign(STUDY, ALLEEG, 9, 'name','ALL','delfiles','off','defaultdesign','off','variable1','type','values1',{'Turn_down_volume_cs','Turn_on_television_cs','Turn_up_volume_cs','Mute_FireTV_cs','Turn_off_FireTV_cs','Apaga_FireTV_cs','Baja_el_volumen_cs','Enciende_la_televisión_cs','Silencia_FireTV_cs','Sube_el_volumen_cs','Apaga_FireTV_os','Baja_el_volumen_os','Enciende_la_televisión_os','Silencia_FireTV_os','Sube_el_volumen_os','Turn_down_volume_os','Turn_on_television_os','Turn_up_volume_os','Mute_FireTV_os','Turn_off_FireTV_os'},'vartype1','categorical','subjselect',{'01','02','03','04','05','06','07','08','10','11','12','13','14','15','16','17','18','19','20'});
% Save study
[STUDY EEG] = pop_savestudy( STUDY, EEG, 'savemode','resave');

%% Stats parameters Set-up
pvalue = 0.05;
correction = 'cluster'; % 'none' or 'cluster'
STUDY = pop_statparams(STUDY, 'condstats','on','singletrials','on','mode','fieldtrip','fieldtripmethod','montecarlo','fieldtripalpha',pvalue,'fieldtripmcorrect',correction);

useDesign = 3;

STUDY = pop_erspparams(STUDY, 'timerange',[-200 1500], 'freqrange',[1 80]);% The longer the range, the bigger the variability

%% Subjects and channels
% IMPORTANTE: Eliminar el final cuando tengamos el sujeto 9 bien
subject_list = setdiff(arrayfun(@(x) sprintf('%02d', x), 1:20, 'UniformOutput', false), {'09'});

% Change to select the channel (typically, a significant channel)
channel = {'CP3'};


%% Set-up output folders

% Paths where to save all the results (Separated by design and channel)
output_dir = fullfile('Significant_TFMaps',STUDY.design(useDesign).name,channel{1});
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