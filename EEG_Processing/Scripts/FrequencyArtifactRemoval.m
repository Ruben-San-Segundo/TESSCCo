function [EEG] = FrequencyArtifactRemoval(EEG, fs, targetFrequency, thresholdFactor, neighbors, sensibility, plotter)

% This function is used to filter specific frequencies that might appear as
% an artifact during recordings, probably due to problems with the EEG amplifier. However, as the appear of the artifacts is
% not constant this funcion compares the power of the specific frequency
% with its neighbours with a threshold factor. In other words, we compare
% the PSD value (averaged from all the channels) with the average of the PSD
% neighbours' values to the desired frequency with a threshold. E.g.
% the power at 80Hz should be 3 times greater than the average power
% between 75 and 85.
% Sensibility is used to take into account not only the desired frequency but [fs-sensibility
% fs+sensibility]
    
    % Obtain the EEG data from the EEGLab dataset
    eeg = EEG.data;
    [nCh, nSamples] = size(eeg);

    % Calculate the PSD. We will use a FFT methode for more precission as
    % the noise is in a very specific narrow band. I. e., we will obtain
    % the values of the spectrum, normalize them by frequency and obtain
    % the power
    spectrum = fft(eeg,[],2); % We could use nfft = newtPow2(nSamples) instead of []
    
    biPSD = abs(spectrum).^2/(nSamples*fs);% Bidirectional average PSD of all the channels
    
    halfIdx = 1:floor(nSamples/2); % Only first half for real signals
    PSD = biPSD(:,halfIdx);

    PSD(:,2:end-1) = 2 * PSD(:, 2:end-1); % To mantain total power in the first half

    PSD = mean(PSD,1); %Mean of all the channels

    freqs = (0:halfIdx(end)-1)*(fs/nSamples); %Frequencies for which the power have been calculated


    % A way more robust to noise is using pwelch. It gives smother curves
    % but with less resolution (in our case, the nois is exactly at 80.5Hz
    % with a very narrow band (around 0.5Hz only).
    % Uncomment below to use pwelch in stead of using DSP by FFT
    % [PSD,freqs] = pwelch(eeg',fs,0,fs/2,fs);
    
        if plotter == true %for debugging and comprobation
            % Old PSD
            figure;
            plot(freqs, 10*log10(PSD), 'b', 'LineWidth', 1.5); hold on;
            % If using the pWelch version, use directly PSD
            xline(targetFrequency, 'r--');
            xlabel('Frequency (Hz)');
            ylabel('Power 10*log_1_0(uV^2/2)');
            grid on;
            title('PSD before notch filter');
        end

    % Create the neighbour band
    targetBand = [targetFrequency-sensibility targetFrequency+sensibility];
    neighborBand = [targetFrequency-neighbors targetFrequency+neighbors];

    % Obtain the index of the frequency and neighbours
    idxTargets = find(freqs >= targetBand(1) & freqs <= targetBand(2));
    idxNeighbors = find((freqs >= neighborBand(1) & freqs < targetBand(1)) | (freqs > targetBand(2) & freqs <= neighborBand(2)));

    % Power values for these frequencies
    pTarget = mean(PSD(idxTargets));
    pMeanNeighbors = mean(PSD(idxNeighbors));

    % Condition
    if pTarget > thresholdFactor * pMeanNeighbors
        fprintf('A peak in %d Hz has been detected: %.2f dB over neighboyrs. Aplying notch filter...\n', ...
            targetFrequency, 10*log10(pTarget/pMeanNeighbors));
        
        % Aplyinng Notch
        EEG = pop_eegfiltnew(EEG, 'locutoff', (targetFrequency-2), 'hicutoff', (targetFrequency+2), 'revfilt', 1);
        % targetFrequency +/- 2 Hz seems to work better
       

        if plotter == true % for debugging and checking

            % Obtain the EEG data from the filtered EEGLab dataset
            eeg = EEG.data;
            [nCh, nSamples] = size(eeg);
        
            % % Calculate the new spectrum
            % spectrum = fft(eeg,[],2); % Ponía fs en vez de nfft
            % freqs = (0:(nSamples-1)) * (fs / nSamples); % Frecuency % PONÍA fs EN VEZ DE nSamples
            % halfIdx = 1:floor(nSamples/2); % Only first half for real signals
            % PSD = mean(abs(spectrum(:,halfIdx)).^2, 1);

             % Calculate the PSD:
            spectrum = fft(eeg,[],2);
            
            biPSD = abs(spectrum).^2/(nSamples*fs); % Bidirectional average PSD of all the channels
            
            halfIdx = 1:floor(nSamples/2); % Only first half for real signals
        
            PSD = biPSD(:,halfIdx);
        
            PSD(:,2:end-1) = 2 * PSD(:, 2:end-1); % Maintain power (except DC and Nyquist)
        
            PSD = mean(PSD,1);
            freqs = (0:halfIdx(end)-1)*(fs/nSamples); 

            % Uncomment to use pWelch version
            % [PSD,freqs] = pwelch(eeg',fs,0,fs/2,fs);

            % New PSD
            figure;
            plot(freqs, 10*log10(PSD), 'b', 'LineWidth', 1.5); hold on;
            % Directly use PSD if pWelch method
            xline(targetFrequency, 'r--');
            xlabel('Frecuencia (Hz)');
            ylabel('Potencia 10*log_1_0(uV^2/Hz)');
            grid on;
            title('PSD after the notch');
        
        
            % % With lower resolution
            % % Obtain the EEG data from the filtered EEGLab dataset
            % eeg = EEG.data;
            % [nCh, nSamples] = size(eeg);
            % 
            % % Calculate the new spectrum
            % spectrum = fft(eeg,fs,2); % Ponía fs en vez de nfft
            % freqs = (0:(fs-1)) * (fs / fs); % Frecuency % PONÍA fs EN VEZ DE nSamples
            % halfIdx = 1:floor(fs/2); % Only first half for real signals
            % PSD = mean(abs(spectrum(:,halfIdx)).^2, 1);
            % 
            % % New PSD
            % figure;
            % plot(freqs(halfIdx), 10*log10(PSD), 'b', 'LineWidth', 1.5); hold on;
            % xline(80, 'r--', '80 Hz');
            % xlabel('Frecuencia (Hz)');
            % ylabel('Potencia (dB)');
            % grid on;
            % title('PSD after the notch');
        end
    else
        fprintf('There is no significan peak in %d Hz.\n', targetFrequency);

    end 

end