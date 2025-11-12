%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Create_Study.m builds an EEGLAB STUDY from per-subject merged epoched datasets and create
% multiple study designs (Spanish/English/ALL, OS/CS/ALL). Then run the
% standard precomputations (ERPs, spectra, ERSP, ITC).
%
% Inputs:
%   - root_dir : parent folder containing Subject_XX subfolders (each must contain `Merged_Clean_epochs.set`)
%
% Effects:
%   - Creates and saves an EEGLAB STUDY (Complete *.study and resaved datasets)
%   - Defines multiple STUDY designs and executes std_precomp to compute ERP/spec/ERS/ITC
%
% Notes:
%   - Script is currently hard-coded to load up to 21 subjects and assign subject/group labels;
%     edit the `std_editset` and `std_makedesign` calls if your subject count or grouping differs.
%   - Requires EEGLAB (and relevant plugins) on the MATLAB path.
%   - Verify event labels in your datasets match the `values1` lists used in the designs.
%
% Author: Mario Lobo (UPM)
% Version: 12-11-2025
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear; close all; clc;


%% Configuration

root_dir = "C:\Users\user\Desktop\Mario Lobo\Silent Speech Data Amazon\3. Pre-processed";
subjects = dir(fullfile(root_dir, 'Subject_*'));

%% Generate the names of the .sets

% Initiate the array
clean_merged_epochs_paths = [];

for i = 1:length(subjects)
      
    %obtain the path of a subject
    subject_path = fullfile(root_dir, subjects(i).name);
    merge_path = fullfile(subject_path, "Merged_Clean_epochs.set");

    % Add the new path to the array
    clean_merged_epochs_paths = [clean_merged_epochs_paths merge_path];


end

%% Call EEGLab
[ALLEEG EEG CURRENTSET ALLCOM] = eeglab;

%% Create the study
[STUDY ALLEEG] = std_editset( STUDY, [], 'commands',{{'index',1,'load',char(clean_merged_epochs_paths(1))},{'index',2,'load',char(clean_merged_epochs_paths(2))},{'index',3,'load',char(clean_merged_epochs_paths(3))},{'index',4,'load',char(clean_merged_epochs_paths(4))},{'index',5,'load',char(clean_merged_epochs_paths(5))},{'index',6,'load',char(clean_merged_epochs_paths(6))},{'index',7,'load',char(clean_merged_epochs_paths(7))},{'index',8,'load',char(clean_merged_epochs_paths(8))},{'index',9,'load',char(clean_merged_epochs_paths(9))},{'index',10,'load',char(clean_merged_epochs_paths(10))},{'index',11,'load',char(clean_merged_epochs_paths(11))},{'index',12,'load',char(clean_merged_epochs_paths(12))},{'index',13,'load',char(clean_merged_epochs_paths(13))},{'index',14,'load',char(clean_merged_epochs_paths(14))},{'index',15,'load',char(clean_merged_epochs_paths(15))},{'index',16,'load',char(clean_merged_epochs_paths(16))},{'index',17,'load',char(clean_merged_epochs_paths(17))},{'index',18,'load',char(clean_merged_epochs_paths(18))},{'index',19,'load',char(clean_merged_epochs_paths(19))},{'index',20,'load',char(clean_merged_epochs_paths(20))},{'index',21,'load',char(clean_merged_epochs_paths(21))},...
    {'index',1,'subject','01'},{'index',2,'subject','02'},{'index',3,'subject','03'},{'index',4,'subject','04'},{'index',5,'subject','05'},{'index',6,'subject','06'},{'index',7,'subject','07'},{'index',8,'subject','08'},{'index',9,'subject','09'},{'index',10,'subject','10'},{'index',11,'subject','11'},{'index',12,'subject','12'},{'index',13,'subject','13'},{'index',14,'subject','14'},{'index',15,'subject','15'},{'index',16,'subject','16'},{'index',17,'subject','17'},{'index',18,'subject','18'},{'index',19,'subject','19'},{'index',20,'subject','20'},{'index',21,'subject','21'},...
    {'index',1,'group','Native'},{'index',2,'group','Native'},{'index',3,'group','Native'},{'index',4,'group','Native'},{'index',5,'group','Native'},{'index',6,'group','Native'},{'index',7,'group','Native'},{'index',8,'group','Native'},{'index',9,'group','Native'},{'index',10,'group','Native'},{'index',11,'group','Native'},{'index',12,'group','Native'},{'index',13,'group','Native'},{'index',14,'group','Native'},{'index',15,'group','Native'},{'index',16,'group','Native'},{'index',17,'group','Native'},{'index',18,'group','Native'},{'index',19,'group','Native'},{'index',20,'group','Native'},{'index',21,'group','Native'}},...
    'updatedat','on' );
[STUDY ALLEEG] = std_checkset(STUDY, ALLEEG);


CURRENTSTUDY = 1; EEG = ALLEEG; CURRENTSET = [1:length(EEG)];
% If it asks to overwrite either the EEG either the ALLEEG, EEG overwrites
% ALLEEG should be selected (it is marked with bold letters in the pop-up)

% Save the study
[STUDY EEG] = pop_savestudy( STUDY, EEG, 'filename','Complete Native.study','filepath',char(root_dir),'resavedatasets','on');
eeglab redraw;

%% Create the designs
% Spanish Designs
STUDY = std_makedesign(STUDY, ALLEEG, 1, 'name','Spanish OS','delfiles','off','defaultdesign','off','variable1','type','values1',{'Apaga_FireTV_os','Baja_el_volumen_os','Enciende_la_televisión_os','Silencia_FireTV_os','Sube_el_volumen_os'},'vartype1','categorical','subjselect',{'01','02','03','04','05','06','07','08','09','10','11','12','13','14','15','16','17','18','19','20','21'});
STUDY = std_makedesign(STUDY, ALLEEG, 2, 'name','Spanish CS','delfiles','off','defaultdesign','off','variable1','type','values1',{'Apaga_FireTV_cs','Baja_el_volumen_cs','Enciende_la_televisión_cs','Silencia_FireTV_cs','Sube_el_volumen_cs'},'vartype1','categorical','subjselect',{'01','02','03','04','05','06','07','08','09','10','11','12','13','14','15','16','17','18','19','20','21'});
STUDY = std_makedesign(STUDY, ALLEEG, 3, 'name','Spanish ALL','delfiles','off','defaultdesign','off','variable1','type','values1',{'Apaga_FireTV_cs','Baja_el_volumen_cs','Enciende_la_televisión_cs','Silencia_FireTV_cs','Sube_el_volumen_cs','Apaga_FireTV_cs','Baja_el_volumen_cs','Enciende_la_televisión_cs','Silencia_FireTV_cs','Sube_el_volumen_cs'},'vartype1','categorical','subjselect',{'01','02','03','04','05','06','07','08','09','10','11','12','13','14','15','16','17','18','19','20','21'});
% English designs
STUDY = std_makedesign(STUDY, ALLEEG, 4, 'name','English OS','delfiles','off','defaultdesign','off','variable1','type','values1',{'Turn_down_volume_os','Turn_on_television_os','Turn_up_volume_os','Mute_FireTV_os','Turn_off_FireTV_os'},'vartype1','categorical','subjselect',{'01','02','03','04','05','06','07','08','09','10','11','12','13','14','15','16','17','18','19','20','21'});
STUDY = std_makedesign(STUDY, ALLEEG, 5, 'name','English CS','delfiles','off','defaultdesign','off','variable1','type','values1',{'Turn_down_volume_cs','Turn_on_television_cs','Turn_up_volume_cs','Mute_FireTV_cs','Turn_off_FireTV_cs'},'vartype1','categorical','subjselect',{'01','02','03','04','05','06','07','08','09','10','11','12','13','14','15','16','17','18','19','20','21'});
STUDY = std_makedesign(STUDY, ALLEEG, 6, 'name','English ALL','delfiles','off','defaultdesign','off','variable1','type','values1',{'Turn_down_volume_os','Turn_on_television_os','Turn_up_volume_os','Mute_FireTV_os','Turn_off_FireTV_os','Turn_down_volume_cs','Turn_on_television_cs','Turn_up_volume_cs','Mute_FireTV_cs','Turn_off_FireTV_cs'},'vartype1','categorical','subjselect',{'01','02','03','04','05','06','07','08','09','10','11','12','13','14','15','16','17','18','19','20','21'});
% Spanish + English Designs
STUDY = std_makedesign(STUDY, ALLEEG, 7, 'name','ALL OS','delfiles','off','defaultdesign','off','variable1','type','values1',{'Apaga_FireTV_os','Baja_el_volumen_os','Enciende_la_televisión_os','Silencia_FireTV_os','Sube_el_volumen_os','Turn_down_volume_os','Turn_on_television_os','Turn_up_volume_os','Mute_FireTV_os','Turn_off_FireTV_os'},'vartype1','categorical','subjselect',{'01','02','03','04','05','06','07','08','09','10','11','12','13','14','15','16','17','18','19','20','21'});
STUDY = std_makedesign(STUDY, ALLEEG, 8, 'name','ALL CS','delfiles','off','defaultdesign','off','variable1','type','values1',{'Turn_down_volume_cs','Turn_on_television_cs','Turn_up_volume_cs','Mute_FireTV_cs','Turn_off_FireTV_cs','Apaga_FireTV_cs','Baja_el_volumen_cs','Enciende_la_televisión_cs','Silencia_FireTV_cs','Sube_el_volumen_cs'},'vartype1','categorical','subjselect',{'01','02','03','04','05','06','07','08','09','10','11','12','13','14','15','16','17','18','19','20','21'});
STUDY = std_makedesign(STUDY, ALLEEG, 9, 'name','ALL','delfiles','off','defaultdesign','off','variable1','type','values1',{'Turn_down_volume_cs','Turn_on_television_cs','Turn_up_volume_cs','Mute_FireTV_cs','Turn_off_FireTV_cs','Apaga_FireTV_cs','Baja_el_volumen_cs','Enciende_la_televisión_cs','Silencia_FireTV_cs','Sube_el_volumen_cs','Apaga_FireTV_os','Baja_el_volumen_os','Enciende_la_televisión_os','Silencia_FireTV_os','Sube_el_volumen_os','Turn_down_volume_os','Turn_on_television_os','Turn_up_volume_os','Mute_FireTV_os','Turn_off_FireTV_os'},'vartype1','categorical','subjselect',{'01','02','03','04','05','06','07','08','09','10','11','12','13','14','15','16','17','18','19','20','21'});
% Save study
[STUDY EEG] = pop_savestudy( STUDY, EEG, 'savemode','resave');
eeglab redraw;

%% Compute the ERPs, DSPs, ERSPs and ITCs
[STUDY, ALLEEG] = std_precomp(STUDY, ALLEEG, {},'savetrials','on','recompute','off','erp','on','spec','on','specparams',{'specmode','fft','logtrials','off'},'ersp','on','erspparams',{'cycles',[3 0.8] ,'nfreqs',100,'ntimesout',500},'itc','on');
