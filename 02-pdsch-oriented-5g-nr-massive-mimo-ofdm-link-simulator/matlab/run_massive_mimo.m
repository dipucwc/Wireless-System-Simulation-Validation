%%
%% Massive MIMO Simulation Run:
%%
%{
The run_massive_mimo script executes the massive MIMO configuration of the simulator, sixty-four transmit antennas,
eight receive antennas, and four spatial layers with wideband eigen-beamforming on the flat Rayleigh channel, and
produces the two results that define the massive claim of the project. The verification gates run first, so no
result can come from an unverified chain.

The first part is the paired beamforming-gain comparison: the same four layers are transmitted either over an
unprecoded four-by-four link or over the sixty-four-antenna eigen-beamformed array at identical total transmit power,
with the random seed reset before each branch so both curves share the same channel and noise realizations. The
horizontal separation of the two bit-error-rate curves is the combined array and beamforming gain, and the script
measures it at the ten-to-the-minus-two operating point by logarithmic interpolation and prints it.

The second part is the end-to-end massive run with least-squares channel estimation: the complete receiver chain,
DM-RS estimation, unbiased MMSE equalization, and the full metric set, executed over the massive SNR grid, with the
aggregate results written to the massive CSV file and the exact configuration archived beside it.

Auxiliary functions:

    config                        Locked configuration; the massive profile is requested explicitly here.
    run_verification_gates        Mandatory verification tests before the runs.
    run_link_curve                Shared engine executing one performance curve per configuration.
    write_config_log              Configuration archive beside the CSV result file.

Output:

    Command Window                Measured beamforming gain and the end-to-end massive results table.
    ber_massive_gain.png          Paired comparison figure, unprecoded 4x4 against SVD 64x8.
    matlab_results_massive.csv    End-to-end massive results with LS estimation: BER, BLER, EVM, NMSE, and the
                                  layer-domain capacity, the reference file of the massive Simulink sweep.
    Configuration log             Exact massive configuration beside the CSV file.
%}


%% Initialization:
%%

clear; clc; close all;

addpath(genpath(pwd));                             % Add the project directory and all subdirectories to the MATLAB path.

cfg = config('massive');                           % Massive profile: 64x8, L = 4, wideband SVD, flat Rayleigh.

rng(cfg.randomSeed);                               % Seed the random generator for a reproducible run.


%% Verification gates:
%%

run_verification_gates(cfg);                       % Execute all mandatory verification tests and abort if any gate fails.


%% Paired beamforming-gain comparison, unprecoded 4x4 against SVD 64x8:
%%

snrE = cfg.snrDb;                                  % Shared SNR grid of the paired comparison.

numFramesE = cfg.numFrames;                        % Frames per SNR point of the comparison.

cfgS = cfg;                                        % Small-array reference branch of the comparison.
cfgS.nTx = 4; cfgS.nRx = 4; cfgS.nLayers = 4;      % Unprecoded four-by-four at full spatial load.
cfgS.precoder = 'identity';

rng(cfg.randomSeed);                               % Seed reset: both branches share channels and noise.
small4 = run_link_curve(cfgS, snrE, numFramesE, true);         % Reference curve with ideal CSI.

rng(cfg.randomSeed);                               % Identical realizations for the massive branch.
massive64 = run_link_curve(cfg, snrE, numFramesE, true);       % Eigen-beamformed 64x8 curve with ideal CSI.


%% Beamforming gain measured at the lowest operating point bracketed by both curves:
%%

targets = [1e-2 3e-2 1e-1];                        % Candidate BER operating points, preferred first. On the
                                                   % massive grid the unprecoded 4x4 curve bottoms out near
                                                   % 4e-2 and the 64x8 curve becomes exactly error-free above
                                                   % 5 dB, so the 1e-2 point is not always bracketed by both
                                                   % positive-BER ranges; the measurement then moves to the
                                                   % lowest bracketed candidate instead of returning NaN.

bracketed = @(curve, t) ...                        % A curve brackets a target when its positive-BER points
    any(curve.ber > 0 & curve.ber <= t) && any(curve.ber >= t);    % lie on both sides of the target level.

target = NaN;                                      % Lowest candidate bracketed by both curves.
for t = targets
    if bracketed(small4, t) && bracketed(massive64, t)
        target = t; break
    end
end
assert(~isnan(target), 'No common BER operating point is bracketed by both curves on this grid.');

snrAt = @(curve) interp1( ...                      % SNR at the target BER by logarithmic interpolation over
    log10(curve.ber(curve.ber > 0)), ...           % the positive-BER points of the curve.
    curve.snrDb(curve.ber > 0), log10(target), 'linear');

snrSmall = snrAt(small4);                          % Operating SNR of the unprecoded 4x4 branch.
snrMassive = snrAt(massive64);                     % Operating SNR of the eigen-beamformed 64x8 branch.
gainDb = snrSmall - snrMassive;                    % Combined array and beamforming gain in decibels.

fprintf(['\nBeamforming gain at BER = %.0e: %.1f dB ' ...
         '(4x4 unprecoded at %.1f dB, 64x8 SVD at %.1f dB)\n\n'], ...
    target, gainDb, snrSmall, snrMassive);


%% Comparison figure:
%%

figDir = fullfile(pwd, cfg.outputFigDir);          % Output directory of the run figures.
if ~exist(figDir,'dir')
    mkdir(figDir);
end

figure(14);                                        % Massive-gain figure of this run.
yS = small4.ber; yS(yS == 0) = NaN;                % Zero-error points hidden on the logarithmic axis.
yM = massive64.ber; yM(yM == 0) = NaN;             % Zero-error points hidden on the logarithmic axis.
semilogy(snrE, yS, '-o', 'LineWidth', 1.2); hold on;           % Unprecoded 4x4 curve.
semilogy(snrE, yM, '-s', 'LineWidth', 1.2);        % Eigen-beamformed 64x8 curve.

lastPos = find(massive64.ber > 0, 1, 'last');      % Last positive-BER point of the massive curve. The zero-error points beyond it are hidden by the logarithmic axis, so the
if lastPos < numel(snrE)                          
    s0 = rng; f0 = build_frame(cfg); rng(s0);      % error-free region is stated as an annotation, with the
    bitsPerPoint = numel(f0.payload) * numFramesE; % evaluated payload bits per point taken from the frame itself.
    text(snrE(lastPos) + 0.4, yM(lastPos), ...
        sprintf('error-free beyond %d dB\n(zero errors in %.1e bits/point)', ...
        snrE(lastPos), bitsPerPoint), 'FontSize', 9, 'VerticalAlignment', 'top');
end
grid on;
xlabel('Total transmit SNR (dB)');
ylabel('BER');
title({'Massive MIMO Beamforming Gain: Unprecoded 4x4 vs SVD 64x8'; ...
    sprintf('16QAM, L = 4, flat Rayleigh, MMSE, ideal CSI, gain %.1f dB at BER %.0e', gainDb, target)});
legend('4x4 unprecoded, MMSE','64x8 SVD eigenbeamforming, MMSE','Location','southwest');
hold off;
saveas(figure(14), fullfile(figDir, 'ber_massive_gain.png'));


%% End-to-end massive run with LS estimation and the full metric set:
%%

rng(cfg.randomSeed);                               % Reproducible end-to-end run.

results = [];                                      % One result row per SNR point.

for isnr = 1:length(cfg.snrDb)                     % Process every SNR point of the massive grid.

    snrDb = cfg.snrDb(isnr);                       % SNR of the current point.

    curve = run_link_curve(cfg, snrDb, cfg.numFrames, false);  % Full receiver chain with LS estimation.

    row.snrDb = snrDb;                             % Aggregates of the point:
    row.ber = curve.ber;                           % Bit error rate.
    row.bler = curve.bler;                         % Block error rate.
    row.evmPercent = 100*curve.evm;                % RMS EVM in percent.
    row.nmse = curve.nmse;                         % Channel-estimation NMSE.
    row.capacityBpsHz = curve.capacity;            % Layer-domain capacity reference; recorded so the Simulink
                                                   % sweep can verify all five metrics against this file.
    row.nTx = cfg.nTx; row.nRx = cfg.nRx;          % Dimensions recorded for traceability.
    row.nLayers = cfg.nLayers;

    results = [results; row]; %#ok<AGROW>

end

T = struct2table(results);                         % Massive results as a table.

outCsv = fullfile(pwd, cfg.outputCsv);             % Configured massive CSV destination.
[folder,~,~] = fileparts(outCsv);
if ~exist(folder,'dir')
    mkdir(folder);
end

writetable(T, outCsv);                             % Store the massive result table.

write_config_log(cfg, outCsv);                     % Archive the exact massive configuration beside it.

disp(T);

fprintf('Saved massive MIMO CSV: %s\n', outCsv);