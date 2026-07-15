
%% Wideband-Precoder Check on the Frequency-Selective Configuration:
%%
%{
The test_tdl_fix script verifies the wideband eigen-beamforming precoder on the frequency-selective configuration
with 16-QAM, four-by-four antennas, two layers, the tapped-delay-line channel, MMSE equalization, and least-squares
estimation. The script runs a short sweep over three SNR points and prints the measured BER, NMSE, and EVM, so the
smooth-in-frequency behavior of the wideband precoder together with the interpolating estimator can be confirmed
directly.

Output:

    Command Window                Measured BER, NMSE, and EVM at each swept SNR point.
%}


%% Initialization:
%%

clear; clc; addpath(genpath(pwd));
cfg = config();                                    % Default configuration: 16QAM, 4x4, L = 2, TDL, MMSE, wideband SVD.
cfg.numFrames = 6;
snrs = [0 10 20];
rng(cfg.randomSeed);


%% Short sweep with LS estimation:
%%

fprintf('%6s %10s %10s %10s\n','SNR','BER','NMSE','EVM(%)');
for s = 1:numel(snrs)
    snrDb = snrs(s); be=0; nb=0; nm=0; ev=0;           % Per-point accumulators.
    for f=1:cfg.numFrames
        frame = build_frame(cfg);                          % One complete transmit frame.
        H = generate_channel(cfg);                         % One independent channel realization.
        W = compute_precoder(cfg,H);                       % Precoder of the current realization.
        [rx,nv] = apply_mimo_channel(frame.layerGrid,H,W,snrDb);       % Channel and receiver noise.
        Ghat = estimate_effective_channel_ls(rx,frame,cfg);            % LS estimate on the DM-RS.
        shat = equalize_mimo(rx,Ghat,frame.dataPositions,nv,cfg);      % Equalized layer symbols.
        met = compute_frame_metrics(shat,frame,Ghat,H,W,snrDb,cfg);    % Frame metric set.
        be=be+met.bitErrors; nb=nb+met.nBits; nm=nm+met.nmse; ev=ev+met.evm;   % Accumulation.
    end
    fprintf('%6.0f %10.3e %10.3e %10.1f\n', snrDb, be/nb, nm/cfg.numFrames, 100*ev/cfg.numFrames);
end
