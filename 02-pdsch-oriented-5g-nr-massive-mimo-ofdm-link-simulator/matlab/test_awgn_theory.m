
%% AWGN QPSK BER Against Closed-Form Theory:
%%
%{
The test_awgn_theory script measures the uncoded QPSK bit error rate on the deterministic AWGN channel and compares
it against the closed-form Q-function expression at three SNR points, in both the ideal-CSI reference mode and the
least-squares estimation mode. Because the channel is deterministic there is no realization variance, so the measured
deviation from theory isolates the Monte Carlo noise and, in the estimation mode, the pilot-noise-limited estimation
loss.

Output:

    Command Window                Simulated BER, theoretical BER, and their deviation in decades per point and mode.
%}


%% Configuration for the deterministic single-antenna comparison:
%%

clear; clc; addpath(genpath(pwd));
cfg = config();
cfg.modulation = 'QPSK'; cfg.bitsPerSymbol = 2;
cfg.channelModel = 'awgn';
cfg.nTx = 1; cfg.nRx = 1; cfg.nLayers = 1; cfg.precoder = 'svd';
cfg.numFrames = 25;
snrs = [4 6 8];
rng(cfg.randomSeed);


%% Sweep in ideal-CSI and LS-estimation modes:
%%

fprintf('%4s %6s %12s %12s %8s\n','SNR','CSI','sim BER','theory','decades');
for mode = 1:2
    for s = 1:numel(snrs)
        snrDb = snrs(s); bitErrors=0; nBits=0;
        for iframe=1:cfg.numFrames
            frame = build_frame(cfg);                  % One complete transmit frame.
            H = generate_channel(cfg);                 % One independent channel realization.
            W = compute_precoder(cfg,H);               % Precoder of the current realization.
            [rx,nv] = apply_mimo_channel(frame.layerGrid,H,W,snrDb);   % Channel and receiver noise.
            if mode==1
                G = true_effective_channel(H,W);
            else
                G = estimate_effective_channel_ls(rx,frame,cfg);
            end
            shat = equalize_mimo(rx,G,frame.dataPositions,nv,cfg);
            met = compute_frame_metrics(shat,frame,G,H,W,snrDb,cfg);
            bitErrors=bitErrors+met.bitErrors; nBits=nBits+met.nBits;  % Bit-error accumulation.
        end
        gs = 10^(snrDb/10);
        th = 0.5*erfc(sqrt(gs)/sqrt(2));           % Closed-form Gray-QPSK bit error rate.
        sim = bitErrors/nBits;                     % Simulated bit error rate of the point.
        if mode==1; lbl='ideal'; else; lbl='LS'; end
        fprintf('%4.0f %6s %12.4e %12.4e %8.3f\n', snrDb, lbl, sim, th, abs(log10(max(sim,1e-12))-log10(th)));
    end
end
