% Do always, or lower the threshold/increase the number of neighbours

function [EEG] = FrequencyArtifactRemovalV2(EEG, fs, targetFrequency, thresholdFactor, neighbors, sensibility, plotter, orderAtenuation)

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
    idxNeighbors = find(freqs >= neighborBand(1) & freqs < targetBand(1) | freqs > targetBand(2) & freqs <= neighborBand(2));

    % Power values for these frequencies
    pTarget = mean(PSD(idxTargets));
    pMeanNeighbors = mean(PSD(idxNeighbors));

    % Condition
    if pTarget > thresholdFactor * pMeanNeighbors
        fprintf('A peak in %d Hz has been detected: %.2f dB over neighboyrs. Aplying notch filter...\n', ...
            targetFrequency, 10*log10(pTarget/pMeanNeighbors));
        
        % Detecting the recomended EEGLab FIR order
        notchWidth = 2;
        auto_order = pop_firwsord('hamming', EEG.srate, notchWidth*2); % ancho de la banda en Hz

        % We do not want a low power component, so we just halve the order
        half_order = ceil(auto_order * orderAtenuation);

        % --- We need an even number ---
        if mod(half_order,2) ~= 0
            half_order = half_order + 1; % forzamos número par
        end

        fprintf('Orden automático: %d | Orden reducido (usado): %d\n', auto_order, half_order);

        % Aplyinng Notch with half the order
        EEG = pop_eegfiltnew(EEG, 'locutoff', (targetFrequency-sensibility), 'hicutoff', (targetFrequency+sensibility), 'revfilt', 1, 'filtorder', auto_order);
        % targetFrequency +/- 2 Hz seems to work fine
       

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

  
            % New PSD
            figure;
            plot(freqs, 10*log10(PSD), 'b', 'LineWidth', 1.5); hold on;
            % Directly use PSD if pWelch method
            xline(targetFrequency, 'r--');
            xlabel('Frecuencia (Hz)');
            ylabel('Potencia 10*log_1_0(uV^2/Hz)');
            grid on;
            title('PSD after the notch');

        end
    else
        fprintf('There is no significan peak in %d Hz.\n', targetFrequency);

    end 

end