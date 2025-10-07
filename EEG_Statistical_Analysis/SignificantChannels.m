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

useDesign = 9;

STUDY = pop_erpparams(STUDY, 'topotime',[0 800]); %The longer the range, the less differences there are (topoplot makes the average during this period)

%% Subjects and channels
% IMPORTANTE: Eliminar el final cuando tengamos el sujeto 9 bien
subject_list = setdiff(arrayfun(@(x) sprintf('%02d', x), 1:20, 'UniformOutput', false), {'09'});

all_channels = {ALLEEG(1).chanlocs.labels};

%% Set-up output variables and folders
%This will allow to save which channel is significant for each subject
significance_matrix = zeros(length(subject_list), length(all_channels));

% Paths where to save all the results (Separated by design)
output_dir = fullfile('Significant_Channels',STUDY.design(useDesign).name);
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
% Count how many times an electrode is marked as a significant
sig_count = sum(significance_matrix, 1);

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
threshold = 5;
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

%% Plot the topographic map with interpolated significance

figure('Name', 'Continous map of recurrence', 'Color', 'w');
% Draw topoplot where values = number of times as significant
topoplot(sig_count, ALLEEG(1).chanlocs, ...
    'maplimits', [0 max(sig_count)], ...
    'style', 'both', ...
    'electrodes', 'ptslabels','emarker2', {highlight_idx, 'o', 'r', 10, 1});
colorbar;
title(sprintf('Mapa de recurrencia de significancia por canal (threshold = %d)',threshold));


% Save figure
saveas(gcf, fullfile(output_dir, 'Topoplot_Continuous_Significance.png'));
