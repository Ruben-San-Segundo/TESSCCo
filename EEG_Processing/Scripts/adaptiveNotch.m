function [EEG, f0, applied] = adaptiveNotch(EEG, searchBand, threshold_dB, debug)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % adaptiveNotch.m detects and removes narrowband noise peaks in an EEGLAB `EEG` structure by
    %   estimating the PSD across channels/trials and applying a band-stop (notch)
    %   FIR filter with `pop_eegfiltnew` when a significant peak is found.
    %
    % Syntax:
    %   [EEG, f0, applied] = adaptiveNotch(EEG)
    %   [EEG, f0, applied] = adaptiveNotch(EEG, searchBand, threshold_dB, debug)
    %
    % Inputs:
    %   - EEG          : EEGLAB EEG structure (channels x samples x trials)
    %   - searchBand   : [minFreq maxFreq] Hz to search for narrowband peaks
    %                    (default: [60 100])
    %   - threshold_dB : Minimum peak prominence in dB to trigger filtering
    %                    (default: 6)
    %   - debug        : logical, when true shows PSD before/after and marks f0
    %                    (default: false)
    %
    % Outputs:
    %   - EEG     : Possibly filtered EEGLAB structure (unchanged if no notch applied)
    %   - f0      : Detected peak frequency (NaN if no peak detected)
    %   - applied : boolean flag, true if notch filter was applied. If true, the main code calls again this function
    %
    % Notes:
    %   - Uses Welch's method (pwelch) to estimate PSD per channel and trial,
    %     averages across channels & trials, then computes peak prominence.
    %   - Filtering is performed with EEGLAB's `pop_eegfiltnew` (requires EEGLAB).
    %   - Bandwidth for the notch is currently fixed to 2 Hz (adjust in code if needed).
    %   - `debug=true` recomputes PSD after filtering and plots a before/after
    %     comparison in a semilogx figure.
    %
    % Author: Mario Lobo (UPM)
    % Version: 12-11-2025
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    if nargin < 2 || isempty(searchBand), searchBand = [60 100]; end
    if nargin < 3 || isempty(threshold_dB), threshold_dB = 6; end
    if nargin < 4, debug = false; end


    fs = EEG.srate;
    data = EEG.data;
    [nCh, nSamples, nTrials] = size(data);

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
