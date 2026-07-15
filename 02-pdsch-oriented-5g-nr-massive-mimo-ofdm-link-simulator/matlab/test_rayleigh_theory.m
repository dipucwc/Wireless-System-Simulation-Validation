
%% Flat-Rayleigh QPSK BER Against Closed-Form Theory:
%%
%{
The test_rayleigh_theory script measures the uncoded QPSK bit error rate on the flat Rayleigh channel with one
independent realization per frame and compares it against the exact closed-form Rayleigh expression at three SNR
points, using the per-bit SNR of Gray-mapped QPSK. The printed ratio of simulation to theory verifies the fading
statistics of the channel generator together with the fixed total-transmit-SNR noise convention.

Output:

    Command Window                Simulated BER, theoretical BER, and their ratio at each swept point.
%}


%% Configuration for the flat-Rayleigh single-antenna comparison:
%%

clear; clc; addpath(genpath(pwd));
cfg = config();
cfg.modulation = 'QPSK'; cfg.bitsPerSymbol = 2;
cfg.channelModel = 'rayleigh_flat';
cfg.nTx = 1; cfg.nRx = 1; cfg.nLayers = 1; cfg.precoder = 'svd';
cfg.numFrames = 25;
snrs = [0 5 10];
rng(cfg.randomSeed);


%% Sweep and comparison:
%%

fprintf('%6s %12s %12s %10s\n','SNR','sim BER','theory BER','ratio');
for s = 1:numel(snrs)
    snrDb = snrs(s); bitErrors=0; nBits=0;
    for iframe=1:cfg.numFrames
        frame = build_frame(cfg);                  % One complete transmit frame.
        H = generate_channel(cfg);                 % One independent channel realization.
        W = compute_precoder(cfg,H);               % Precoder of the current realization.
        [rx,nv] = apply_mimo_channel(frame.layerGrid,H,W,snrDb);   % Channel and receiver noise.
        Ghat = estimate_effective_channel_ls(rx,frame,cfg);
        shat = equalize_mimo(rx,Ghat,frame.dataPositions,nv,cfg);
        met = compute_frame_metrics(shat,frame,Ghat,H,W,snrDb,cfg);
        bitErrors=bitErrors+met.bitErrors; nBits=nBits+met.nBits;  % Bit-error accumulation.
    end
    g = 10^(snrDb/10);
    th = 0.5*(1 - sqrt(g/(1+g)));                  % Exact flat-Rayleigh expression at the per-bit SNR of Gray QPSK.
    sim = bitErrors/nBits;                     % Simulated bit error rate of the point.
    fprintf('%6.0f %12.4e %12.4e %10.2f\n', snrDb, sim, th, sim/th);
end
