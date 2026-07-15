%%
%% RF Measurement Figures from the Logged Run:
%%
%{
The plot_rf_measurements script draws the three RF measurement figures from the logged signals of the last Simulink
run, log_txWaveform and log_shat, written by the measurement branch of add_rf_measurements. Everything here is base
MATLAB; no DSP System Toolbox or Communications Toolbox is required.

14 Figure shows the transmit power spectral density of the CP-OFDM waveform by Welch estimation, averaged over all
logged frames and antennas, with the occupied band marked inside the sampled band. The segments are Hann-windowed and
deliberately not aligned to the OFDM symbol boundaries: a symbol-synchronized rectangular periodogram returns exactly
the subcarrier values and hides the out-of-band sinc skirts, while this estimate shows the true RF spectrum, matching
the live Spectrum Analyzer view. Figure 15  shows the PAPR CCDF of the waveform, evaluated per OFDM symbol over all
frames and antennas, which is the classic OFDM RF-headroom curve. Figure 16 shows the equalized constellation of the
last frame with all layers overlaid, the equalized-symbol view of the simulator. The three figures are saved as PNG
files beside the model.

Auxiliary functions:

    config
        Locked simulation configuration providing the numerology of the logged waveform.

Input:

    log_txWaveform                Logged transmit waveform of the last model run, samples x nTx x frames.
    log_shat                      Logged equalized symbols of the last model run.

Output:

    rf_psd.png                    Transmit power spectral density figure.
    rf_papr_ccdf.png              PAPR CCDF figure.
    rf_constellation.png          Equalized constellation figure.
%}


%% Inputs from the run:
%%

addpath(genpath(pwd));                             % The configuration function must be reachable.

if ~exist('log_txWaveform', 'var') || ~exist('log_shat', 'var')    % Both logs must exist in the workspace.
    error(['Logs not found. Run add_rf_measurements once, then run the model, ' ...
           'then call plot_rf_measurements.']);
end

cfg = config();                                    % Load the locked simulation configuration.

fs = cfg.nFFT * cfg.subcarrierSpacingHz;           % Sample rate of the compact grid.

cpLen = round(cfg.nFFT/14);                        % Cyclic-prefix length of the compact numerology.

symLen = cfg.nFFT + cpLen;                         % Samples per OFDM symbol including the prefix.

nSym = cfg.nSymbols;                               % OFDM symbols per logged slot.

wf = log_txWaveform;                               % Logged waveform, samples x nTx x frames.

if ndims(wf) == 2; wf = reshape(wf, size(wf,1), size(wf,2), 1); end    % Single-frame logs get a frame dimension.

[nSamp, nTx, nFrames] = size(wf);                  % Dimensions of the logged waveform.

fprintf('Logged waveform: %d samples x %d antennas x %d frames, Fs = %.4g MHz\n', ...
    nSamp, nTx, nFrames, fs/1e6);


%% PSD by Welch estimation over the continuous waveform:
%%

L = 2*cfg.nFFT;                                    % Segment length of the Welch estimate.

hop = L/2;                                         % Fifty percent segment overlap.

w = 0.5*(1 - cos(2*pi*(0:L-1).'/(L-1)));           % Hann window in base MATLAB.

U = sum(w.^2);                                     % Window energy for the PSD normalization.

acc = zeros(L, 1);                                 % Accumulated periodograms.
cnt = 0;                                           % Number of accumulated segments.

for f = 1:nFrames                                  % One logged frame per iteration.
    for a = 1:nTx                                  % One antenna stream per iteration.
        x = wf(:, a, f);                           % Continuous waveform of this stream.
        for s0 = 1:hop:(nSamp - L + 1)             % Overlapping segments over the slot.
            seg = w .* x(s0:s0+L-1);               % Windowed segment.
            acc = acc + abs(fftshift(fft(seg))).^2;            % Centered periodogram of the segment.
            cnt = cnt + 1;
        end
    end
end

psd = acc / cnt / U;                               % Averaged and window-normalized PSD estimate.

fAxis = ((-L/2):(L/2-1)).' * fs / L / 1e6;         % Frequency axis in megahertz.

figure(14); clf;

plot(fAxis, 10*log10(psd + eps), 'LineWidth', 1.2);            % PSD in decibels, protected against log of zero.

grid on;                                           % Enable the major plot grid.

xlabel('Frequency (MHz)');                         % Label the horizontal frequency axis.

ylabel('PSD (dB, relative)');                      % Label the vertical spectral-density axis.

title({'Transmit PSD of the CP-OFDM waveform (Welch, Hann window)'; ...    % Title with the grid occupancy.
    sprintf('%d subcarriers of %d-point FFT: %.3g MHz occupied in %.3g MHz sampled', ...
    cfg.nSC, cfg.nFFT, cfg.nSC*cfg.subcarrierSpacingHz/1e6, fs/1e6)});

xline(+cfg.nSC*cfg.subcarrierSpacingHz/2e6, '--'); % Upper occupied-band edge marker.

xline(-cfg.nSC*cfg.subcarrierSpacingHz/2e6, '--'); % Lower occupied-band edge marker.

legend('Welch PSD estimate', 'Occupied-band edge', 'Location', 'south');   % Identify the curves.


%% PAPR CCDF per OFDM symbol:
%%

papr = zeros(nSym*nTx*nFrames, 1); i = 0;          % Per-symbol PAPR values over all streams and frames.

for f = 1:nFrames                                  % One logged frame per iteration.
    for a = 1:nTx                                  % One antenna stream per iteration.
        for m = 1:nSym                             % One OFDM symbol per iteration.
            x = wf((m-1)*symLen + (1:symLen), a, f);           % Samples of this symbol including the prefix.
            i = i + 1;
            papr(i) = max(abs(x).^2) / mean(abs(x).^2);        % Peak-to-average power ratio of the symbol.
        end
    end
end

paprDb = 10*log10(papr(1:i));                      % PAPR values in decibels.

thr = 4:0.1:12;                                    % Threshold grid of the CCDF.

ccdf = arrayfun(@(t) mean(paprDb > t), thr);       % Exceedance probability per threshold.

figure(15); clf;

semilogy(thr, max(ccdf, 1/i), 'LineWidth', 1.2);   % CCDF floored at one count for the logarithmic axis.

grid on;                                           % Enable the major plot grid.

xlabel('PAPR threshold (dB)');                     % Label the horizontal threshold axis.

ylabel('Prob(PAPR > threshold)');                  % Label the vertical probability axis.

title({'PAPR CCDF of the CP-OFDM waveform'; ...    % Title with the measurement population.
    sprintf('%d OFDM symbols, %d antennas, %d frames', nSym, nTx, nFrames)});

legend('Measured CCDF', 'Location', 'southwest');  % Identify the measured curve.


%% Equalized constellation of the last frame:
%%

sh = log_shat;                                     % Logged equalized symbols.

if ndims(sh) == 3
    sh = sh(:,:,end);                              % Last frame of the run.
elseif isvector(sh)
    sh = sh(:);                                    % Single-layer or single-frame case.
end

figure(16); clf;

plot(real(sh(:)), imag(sh(:)), '.', 'MarkerSize', 4);          % All layers overlaid as a scatter plot.

grid on; axis square;                              % Square axes for the constellation view.

axis([-1.6 1.6 -1.6 1.6]);                         % Fixed range around the unit-power constellation.

xlabel('In-phase');                                % Label the horizontal component axis.

ylabel('Quadrature');                              % Label the vertical component axis.

title({sprintf('Equalized %s constellation, last frame, all layers', upper(cfg.modulation)); ...
    'Set the SNR (dB) block to compare low against high SNR'});

legend('Equalized data symbols', 'Location', 'northeast');     % Identify the symbol cloud.


%% Save the three measurement figures as PNG files:
%%

saveas(figure(14), 'rf_psd.png');                 % Power-spectral-density figure.

saveas(figure(15), 'rf_papr_ccdf.png');           % PAPR CCDF figure.

saveas(figure(16), 'rf_constellation.png');       % Equalized-constellation figure.

fprintf(['Figures 14 (PSD), 15(PAPR CCDF), 16 (constellation) drawn and saved:\n' ...
         '    rf_psd.png, rf_papr_ccdf.png, rf_constellation.png\n']);
