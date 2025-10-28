function [EEG, f0, applied] = adaptiveNotch(EEG, searchBand, threshold_dB, debug)
    % adaptiveNotch_eeglab - Global adaptive notch filtering for EEGLAB EEG structure.
    %
    % Detects a narrowband noise peak (e.g., ~80 Hz) across all channels,
    % and applies a notch filter to the whole dataset using pop_eegfiltnew.
    % Optionally visualizes the PSD before and after filtering.
    %
    % Syntax:
    %   [EEG, f0, applied] = adaptiveNotch_eeglab(EEG)
    %   [EEG, f0, applied] = adaptiveNotch_eeglab(EEG, searchBand, threshold_dB, debug)
    %
    % Inputs:
    %   EEG          : EEGLAB EEG structure
    %   searchBand   : [minFreq maxFreq] range (default: [60 100])
    %   threshold_dB : Peak prominence threshold in dB (default: 6)
    %   debug        : true/false → show PSD plot (default: false)
    %
    % Outputs:
    %   EEG       : Filtered EEG structure (same as input if no filtering applied)
    %   f0        : Detected noise frequency (NaN if none)
    %   applied   : Boolean flag indicating whether the filter was applied
    %
    % Example:
    %   [EEG, f0, applied] = adaptiveNotch_eeglab(EEG, [70 90], 8, true);
    %
    % Requires: EEGLAB, pop_eegfiltnew()
    % --------------------------------------------------------------

    if nargin < 2 || isempty(searchBand), searchBand = [60 100]; end
    if nargin < 3 || isempty(threshold_dB), threshold_dB = 6; end
    if nargin < 4, debug = false; end


    fs = EEG.srate;
    data = EEG.data;
    [nCh, nSamples, nTrials] = size(data);

    % % Compute average PSD across all channels
    % 
    % [Pxx, f] = pwelch(data(1,:), fs, [], [], fs);
    % Pxx_all = zeros(length(Pxx), nCh);
    % Pxx_all(:,1) = Pxx;
    % 
    % for ch = 2:nCh
    %     [Pxx_all(:, ch), ~] = pwelch(data(ch,:), fs, [], [], fs);
    % end
    % 
    % Pxx_mean = mean(Pxx_all, 2);
    % Pxx_dB = 10*log10(Pxx_mean);

    % Use Welch's method for the first channel & trial to get freq vector
    [Pxx, f] = pwelch(data(1,:,1), fs, [], [], fs);
    Pxx_all = zeros(length(Pxx), nCh, nTrials);

    for tr = 1:nTrials
        for ch = 1:nCh
            [Pxx_all(:, ch, tr), ~] = pwelch(data(ch,:,tr), fs, [], [], fs);
        end
    end

    % Average across channels and trials
    Pxx_mean = mean(Pxx_all, [2 3]);
    Pxx_dB = 10*log10(Pxx_mean);

    % Search for a peak in the specified band
    idx = f >= searchBand(1) & f <= searchBand(2);

    f_band = f(idx);
    P_band = Pxx_dB(idx);

    [peak_val, iMax] = max(P_band);
    mean_val = mean(P_band);
    prominence = peak_val - mean_val;

    applied = false;
    f0 = NaN;
    EEG_before = EEG;

    % --- Decision: filter or not ---
    if prominence >= threshold_dB
        f0 = f_band(iMax);
        bw = 2; % Hz bandwidth for pop_eegfiltnew (can adjust if needed)
        fprintf('Detected global peak at %.2f Hz (prominence %.1f dB) → applying notch.\n', f0, prominence);
        EEG = pop_eegfiltnew(EEG, 'locutoff', f0 - bw/2, 'hicutoff', f0 + bw/2, 'revfilt', 1);
        applied = true;
    else
        fprintf('No significant narrowband noise detected (prominence %.1f dB < %.1f dB threshold)\n', prominence, threshold_dB);
    end

    % --- Optional visualization ---
    if debug
        % Compute PSD again if filtering was applied
        [Pxx_after, ~] = pwelch(EEG.data(1,:,1), fs, [], [], fs);
        for tr = 1:nTrials
            for ch = 1:nCh
                [tmp, ~] = pwelch(EEG.data(ch,:,tr), fs, [], [], fs);
                Pxx_after = Pxx_after + tmp;
            end
        end
        Pxx_after = Pxx_after / (nCh*nTrials);
        Pxx_after_dB = 10*log10(Pxx_after);

        % Plot comparison
        figure('Name','Adaptive Notch Debug','Color','w');
        hold on;
        semilogx(f, Pxx_dB, 'b', 'LineWidth', 1.2);
        semilogx(f, Pxx_after_dB, 'r', 'LineWidth', 1.2);
        ylimits = ylim;
        fill([searchBand(1) searchBand(2) searchBand(2) searchBand(1)], ...
             [ylimits(1) ylimits(1) ylimits(2) ylimits(2)], ...
             [0.9 0.9 0.9], 'EdgeColor','none', 'FaceAlpha', 0.3);

        if applied
            xline(f0, '--k', sprintf('f₀ = %.1f Hz', f0), 'LabelVerticalAlignment','bottom');
        end

        xlabel('Frequency (Hz)');
        ylabel('Power Spectral Density (dB/Hz)');
        title('EEG PSD before and after adaptive notch filtering');
        legend('Before filtering','After filtering','Location','best');
        grid on;
        hold off;
    end
end
