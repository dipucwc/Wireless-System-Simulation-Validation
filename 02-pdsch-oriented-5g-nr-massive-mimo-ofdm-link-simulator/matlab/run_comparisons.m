 
%% Comparison Runs and Overlay Figures:
%%
%{
The run_comparisons script executes the comparison runs of the simulator and produces the overlay figures eight to
thirteen. The script begins by initializing the workspace, loading the locked configuration, seeding the random
number generator for reproducibility, and executing the four verification gates so that no comparison result can be
generated on an unverified processing chain.

Run A configures a single-antenna AWGN link with ideal channel state information and sweeps QPSK and 16-QAM over the
SNR grid; the simulated bit error rates are overlaid on the closed-form Gray-mapping expressions, so the figure is a
direct numerical validation of the transmitter, channel, receiver, and metric chain against theory. Run B configures
the flat Rayleigh fading case, in which one independent channel realization is drawn per frame and held constant
across subcarriers, and overlays the simulated QPSK bit error rate on the closed-form Rayleigh reference, with the
AWGN theory curve included so that the loss of diversity is visible as the change from a waterfall to a straight-line
slope on the logarithmic axis. Run C configures the four-by-four 16-QAM link at full spatial load, with the layer
count equal to the receive-antenna count, and produces three curves on one axis: the zero-forcing equalizer with
ideal channel state information, the MMSE equalizer with ideal channel state information, and the MMSE equalizer
operating on the least-squares DM-RS channel estimate; the separation between the first two curves quantifies the
noise-enhancement penalty of zero forcing, and the separation between the last two quantifies the channel-estimation
loss. Run D evaluates the ergodic antenna-domain capacity over independent Rayleigh realizations for the two-by-two,
four-by-four, and eight-by-eight configurations together with the sixty-four-by-eight massive array, and overlays
the four curves: the square configurations show the high-SNR slope scaling with the minimum antenna count, while
the massive curve shares the slope of eight spatial dimensions but sits above the eight-by-eight curve by the array
gain of the sixty-four-antenna aperture, the channel-hardening signature of the massive regime. Run E evaluates the                
massive MIMO configuration: the same four spatial layers are transmitted either over an unprecoded four-by-four link 
or over a sixty-four-antenna array with wideband eigen-beamforming at identical total transmit power, and the horizontal
separation of the two bit-error-rate curves measures the combined array and beamforming gain. Finally, the script draws the
equalized 16-QAM constellations of a single frame at a low and a high SNR point side by side, providing a direct visual confirmation 
of symbol recovery.

All runs reuse the identical verified processing chain through the run_link_curve function, every figure is annotated
with axis labels, a title carrying the configuration, and a legend identifying each curve, and every figure is saved
as a PNG file to the configured output directory.

Auxiliary functions:

    config                        Locked simulation configuration.
    run_verification_gates        Mandatory verification tests before any comparison run.
    run_link_curve                Shared engine executing one performance curve per configuration.
    build_frame                   Payload size lookup for the error-free annotation of Run E.

Output:

    PNG comparison figures        Figures eight to thirteen stored in the configured output directory.
%}


%% Initialization:
%%

clear; 
clc; 
close all;
addpath(genpath(pwd));
base = config();                                   % Locked simulation configuration.
rng(base.randomSeed);                              % Reproducible comparison runs.
run_verification_gates(base);                      % Gates abort the script on any failure.
figDir = fullfile(pwd, base.outputFigDir);         % Output directory of the comparison figures.
if ~exist(figDir,'dir'); mkdir(figDir); end
numFramesA = 100;                                  % AWGN: deterministic channel, modest frame count suffices.
numFramesB = 300;                                  % Rayleigh: many realizations for the fading average.
numFramesC = 100;                                  % Equalizer comparison.


%% Run A, AWGN BER against closed-form theory (SISO, ideal CSI):
%%

cfgA = base;
cfgA.channelModel = 'awgn';
cfgA.nTx = 1; cfgA.nRx = 1; cfgA.nLayers = 1; cfgA.precoder = 'svd';
snrA = 0:2:14;

cfgA.modulation = 'QPSK'; cfgA.bitsPerSymbol = 2;
qpskA = run_link_curve(cfgA, snrA, numFramesA, true);      % QPSK curve with ideal CSI.
cfgA.modulation = '16QAM'; cfgA.bitsPerSymbol = 4;
qam16A = run_link_curve(cfgA, snrA, numFramesA, true);     % 16-QAM curve with ideal CSI.

gs = 10.^(snrA/10);                                % Linear symbol SNR of the grid.
thQpsk = 0.5*erfc(sqrt(gs)/sqrt(2));               % Closed-form Gray-QPSK bit error rate.
th16 = (3/4)*(0.5*erfc(sqrt(3*gs/15)/sqrt(2)));    % Gray-mapping 16-QAM approximation.

figure(8)                                          % AWGN theory-comparison figure.
yq = qpskA.ber; yq(yq==0) = NaN;                   % Zero-error points cannot be shown on a logarithmic axis.
y16 = qam16A.ber; y16(y16==0) = NaN;               % Zero-error points hidden on the logarithmic axis.
semilogy(snrA, yq, 'o', 'LineWidth', 1.2); hold on;            % Simulated QPSK points.
semilogy(snrA, thQpsk, '-', 'LineWidth', 1.2);     % Closed-form QPSK curve.
semilogy(snrA, y16, 's', 'LineWidth', 1.2);        % Simulated 16-QAM points.
semilogy(snrA, th16, '--', 'LineWidth', 1.2);      % Closed-form 16-QAM curve.
grid on;
xlabel('Total transmit SNR (dB)');
ylabel('BER');
title({'Uncoded BER in AWGN: Simulation vs Closed-Form Theory'; 'SISO, ideal CSI'});
legend('QPSK simulation','QPSK theory','16-QAM simulation','16-QAM theory','Location','southwest');
hold off;
saveas(figure(8), fullfile(figDir, 'ber_awgn_vs_theory.png'));


%% Run B, flat-Rayleigh QPSK BER against the closed-form reference (SISO, ideal CSI):
%%

cfgB = base;
cfgB.channelModel = 'rayleigh_flat';
cfgB.modulation = 'QPSK'; cfgB.bitsPerSymbol = 2;
cfgB.nTx = 1; cfgB.nRx = 1; cfgB.nLayers = 1; cfgB.precoder = 'svd';
snrB = 0:5:30;
rayB = run_link_curve(cfgB, snrB, numFramesB, true);       % Flat-Rayleigh QPSK curve.

gb = 10.^(snrB/10)/2;                              % Per-bit SNR of Gray-mapped QPSK.
thRay = 0.5*(1 - sqrt(gb./(1+gb)));                % Exact flat-Rayleigh expression.
gsB = 10.^(snrB/10);
thAwgnB = 0.5*erfc(sqrt(gsB)/sqrt(2));             % AWGN reference for the diversity contrast.
thAwgnB = max(thAwgnB, 1e-8);                      % Floor the reference so extreme underflow cannot stretch the axis.

figure(9)                                          % Rayleigh theory-comparison figure.
yr = rayB.ber; yr(yr==0) = NaN;                    % Zero-error points hidden on the logarithmic axis.
semilogy(snrB, yr, 'o', 'LineWidth', 1.2); hold on;            % Simulated Rayleigh points.
semilogy(snrB, thRay, '-', 'LineWidth', 1.2);      % Closed-form Rayleigh curve.
semilogy(snrB, thAwgnB, '--', 'LineWidth', 1.2);   % AWGN reference for the diversity contrast.
grid on;
xlabel('Total transmit SNR (dB)');
ylabel('BER');
title({'Uncoded QPSK BER in Flat Rayleigh Fading vs Closed-Form Theory'; 'SISO, ideal CSI'});
legend('Rayleigh simulation','Rayleigh theory','AWGN theory reference','Location','southwest');
ylim([1e-6 1]);                                    % Axis limited to the meaningful BER range.
hold off;
saveas(figure(9), fullfile(figDir, 'ber_rayleigh_vs_theory.png'));


%% Run C, ZF vs MMSE with ideal CSI and LS estimation (full spatial load, flat Rayleigh):
%%

cfgC = base;
cfgC.channelModel = 'rayleigh_flat';
cfgC.modulation = '16QAM'; cfgC.bitsPerSymbol = 4;
cfgC.nLayers = 4;                                  % Full spatial load, L = nRx: the regime where ZF noise
                                                   % enhancement is severe and the MMSE advantage appears;
                                                   % at L < nRx the system is under-loaded and the two
                                                   % equalizers nearly coincide.
cfgC.precoder = 'identity';                        % Unprecoded multiplexing: under eigen-beamforming the
                                                   % effective Gram matrix is diagonal on a flat channel and
                                                   % ZF and MMSE provably coincide, so the comparison
                                                   % requires the unprecoded general channel matrix.
snrC = 0:5:25;

cfgC.equalizer = 'zf';                             % The seed is reset before every branch so all three curves
rng(base.randomSeed);                              % share identical channels and noise, turning the comparison
zfIdeal = run_link_curve(cfgC, snrC, numFramesC, true);    % into a paired experiment with far lower variance.
cfgC.equalizer = 'mmse';
rng(base.randomSeed);
mmseIdeal = run_link_curve(cfgC, snrC, numFramesC, true);
rng(base.randomSeed);
mmseLs = run_link_curve(cfgC, snrC, numFramesC, false);

figure(10)                                         % Equalizer-comparison figure.
y1 = zfIdeal.ber; y1(y1==0) = NaN;                 % Zero-error points hidden on the logarithmic axis.
y2 = mmseIdeal.ber; y2(y2==0) = NaN;               % Zero-error points hidden on the logarithmic axis.
y3 = mmseLs.ber; y3(y3==0) = NaN;                  % Zero-error points hidden on the logarithmic axis.
semilogy(snrC, y1, '-^', 'LineWidth', 1.2); hold on;           % ZF with ideal CSI.
semilogy(snrC, y2, '-o', 'LineWidth', 1.2);        % MMSE with ideal CSI.
semilogy(snrC, y3, '-s', 'LineWidth', 1.2);        % MMSE on the LS estimate.
grid on;
xlabel('Total transmit SNR (dB)');
ylabel('BER');
title({'ZF vs MMSE Equalization, Ideal CSI and LS Estimation'; sprintf('16QAM, %dx%d, L = %d, flat Rayleigh', cfgC.nTx, cfgC.nRx, cfgC.nLayers)});
legend('ZF, ideal CSI','MMSE, ideal CSI','MMSE, LS estimation','Location','southwest');
hold off;
saveas(figure(10), fullfile(figDir, 'ber_zf_vs_mmse.png'));


%% Run D, ergodic MIMO capacity for three square configurations:
%%

snrD = 0:5:25;                                     % SNR grid of the capacity comparison.
nReal = 200;                                       % Channel realizations per SNR point.
configs = [2 2; 4 4; 8 8; 64 8];                   % Square configurations plus the 64x8 massive array.
capD = zeros(numel(snrD), size(configs,1));        % Capacity per point and configuration.
for c = 1:size(configs,1)
    nT = configs(c,1); nR = configs(c,2);
    for s = 1:numel(snrD)
        rho = 10^(snrD(s)/10);                     % Linear SNR of the point.
        acc = 0;                                   % Accumulated capacity over the realizations.
        for r = 1:nReal
            Hk = (randn(nR,nT)+1j*randn(nR,nT))/sqrt(2);       % One iid Rayleigh realization.
            acc = acc + real(log2(det(eye(nR) + (rho/nT)*(Hk*Hk'))));   % Capacity contribution.
        end
        capD(s,c) = acc/nReal;                     % Ergodic average of the point.
    end
end

figure(11)                                         % Capacity-comparison figure.
plot(snrD, capD(:,1), '-o', 'LineWidth', 1.2); hold on;        % Two-by-two curve.
plot(snrD, capD(:,2), '-s', 'LineWidth', 1.2);     % Four-by-four curve.
plot(snrD, capD(:,3), '-^', 'LineWidth', 1.2);     % Eight-by-eight curve.
plot(snrD, capD(:,4), '-d', 'LineWidth', 1.2);     % Sixty-four-by-eight massive curve.
grid on;
xlabel('Total transmit SNR (dB)');
ylabel('Ergodic capacity (bit/s/Hz)');
title({'Ergodic MIMO Capacity vs SNR'; 'iid Rayleigh, equal power allocation, including the 64x8 massive array'});
legend('2x2','4x4','8x8','64x8 massive','Location','northwest');
hold off;
saveas(figure(11), fullfile(figDir, 'capacity_multi_config.png'));


%% Run E, massive MIMO beamforming gain, unprecoded 4x4 vs SVD 64x8:
%%

cfgE = base;                                       % The same four layers are sent either over an unprecoded
cfgE.channelModel = 'rayleigh_flat';               % 4x4 link or over a 64-antenna eigen-beamformed array at
cfgE.modulation = '16QAM'; cfgE.bitsPerSymbol = 4; % identical total transmit power, so the horizontal curve
cfgE.equalizer = 'mmse';                           % separation is the combined array and beamforming gain.
snrE = -10:5:20;
numFramesE = 60;

cfgE.nTx = 4; cfgE.nRx = 4; cfgE.nLayers = 4; cfgE.precoder = 'identity';
rng(base.randomSeed);
small4 = run_link_curve(cfgE, snrE, numFramesE, true);     % Unprecoded 4x4 reference curve.

cfgE.nTx = 64; cfgE.nRx = 8; cfgE.nLayers = 4; cfgE.precoder = 'svd';
rng(base.randomSeed);
massive64 = run_link_curve(cfgE, snrE, numFramesE, true);  % Eigen-beamformed 64x8 curve.

figure(13)                                         % Massive-array comparison figure.
yS = small4.ber; yS(yS==0) = NaN;                  % Zero-error points hidden on the logarithmic axis.
yM = massive64.ber; yM(yM==0) = NaN;               % Zero-error points hidden on the logarithmic axis.
semilogy(snrE, yS, '-o', 'LineWidth', 1.2); hold on;           % Unprecoded 4x4 curve.
semilogy(snrE, yM, '-s', 'LineWidth', 1.2);        % Eigen-beamformed 64x8 curve.
grid on;
xlabel('Total transmit SNR (dB)');
ylabel('BER');
title({'Massive MIMO Beamforming Gain: Unprecoded 4x4 vs SVD 64x8'; '16QAM, L = 4, flat Rayleigh, MMSE, ideal CSI, equal total transmit power'});
legend('4x4 unprecoded, MMSE','64x8 SVD eigenbeamforming, MMSE','Location','southwest');
lastIdx = find(~isnan(yM), 1, 'last');             % Beyond the last plotted point the run measured zero bit
if ~isempty(lastIdx) && lastIdx < numel(snrE)      % errors, so the true BER lies below the Monte Carlo
    tmpFrame = build_frame(cfgE);                  % resolution and zero cannot be drawn on a logarithmic axis;
    bitsPerPoint = numFramesE * length(tmpFrame.payload);   % the annotation states the bits measured per point.
    text(snrE(lastIdx)+0.4, yM(lastIdx), ...
        sprintf('error-free beyond %d dB\n(zero errors in %.2g bits/point)', ...
        snrE(lastIdx), bitsPerPoint), 'FontSize', 9);
end
hold off;
saveas(figure(13), fullfile(figDir, 'ber_massive_64x8_vs_4x4.png'));


%% Figure 12, equalized 16-QAM constellations at low and high SNR (MMSE, LS):
%%

cfgF = base; cfgF.equalizer = 'mmse';              % The constellation figure uses the main configuration
rng(base.randomSeed);                              % (wideband eigen-beamforming, L = 2, TDL, LS, MMSE) rather
lowSnr = run_link_curve(cfgF, 10, 1, false);       % than the full-load unprecoded one: under full load the
rng(base.randomSeed);                              % residual inter-layer interference smears the clusters even
highSnr = run_link_curve(cfgF, 25, 1, false);      % smeared clusters defeat a recovery demonstration.

figure(12)                                         % Constellation figure at two operating points.
subplot(1,2,1)                                     % Low-SNR panel.
plot(real(lowSnr.shatSample(:)), imag(lowSnr.shatSample(:)), '.', 'MarkerSize', 4);    % Equalized symbols at 10 dB.
grid on; axis square; axis([-1.6 1.6 -1.6 1.6]);
xlabel('In-phase'); ylabel('Quadrature');
title('Equalized 16-QAM, 10 dB');
legend('Equalized data symbols','Location','northeast');
subplot(1,2,2)                                     % High-SNR panel.
plot(real(highSnr.shatSample(:)), imag(highSnr.shatSample(:)), '.', 'MarkerSize', 4);  % Equalized symbols at 25 dB.
grid on; axis square; axis([-1.6 1.6 -1.6 1.6]);
xlabel('In-phase'); ylabel('Quadrature');
title('Equalized 16-QAM, 25 dB');
legend('Equalized data symbols','Location','northeast');
saveas(figure(12), fullfile(figDir, 'constellation_low_high_snr.png'));

fprintf('Comparison figures 8-13 saved to: %s\n', figDir);
