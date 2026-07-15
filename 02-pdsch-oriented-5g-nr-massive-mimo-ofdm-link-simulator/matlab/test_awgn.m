
%% End-to-End AWGN Sanity Check:
%%
%{
The test_awgn script runs the complete chain on the deterministic AWGN channel with single-antenna QPSK at a high SNR
point and confirms error-free recovery. Passing this check proves the scrambling, CRC attachment, bit ordering,
equalization, and demapping operate together correctly, because a single inconsistency anywhere in the chain would
produce bit errors at this operating point.

Output:

    Command Window                Measured BER, BLER, delivered bits per frame, NMSE, and the pass/fail verdict.
%}


%% Configuration for the deterministic single-antenna check:
%%

clear; clc; addpath(genpath(pwd));
cfg = config();
cfg.modulation = 'QPSK'; cfg.bitsPerSymbol = 2;
cfg.channelModel = 'awgn';
cfg.nTx = 1; cfg.nRx = 1; cfg.nLayers = 1; cfg.precoder = 'svd';
cfg.numFrames = 5; cfg.snrDb = 30;
rng(cfg.randomSeed);


%% Frame loop and verdict:
%%

bitErrors=0; nBits=0; blockErrors=0; paySucc=0;    % Run accumulators.
for iframe=1:cfg.numFrames
    frame = build_frame(cfg);                          % One complete transmit frame.
    H = generate_channel(cfg);                         % One independent channel realization.
    W = compute_precoder(cfg,H);                       % Precoder of the current realization.
    [rx,nv] = apply_mimo_channel(frame.layerGrid,H,W,cfg.snrDb);   % Channel and receiver noise.
    Ghat = estimate_effective_channel_ls(rx,frame,cfg);            % LS estimate on the DM-RS.
    shat = equalize_mimo(rx,Ghat,frame.dataPositions,nv,cfg);      % Equalized layer symbols.
    met = compute_frame_metrics(shat,frame,Ghat,H,W,cfg.snrDb,cfg);   % Frame metric set.
    bitErrors=bitErrors+met.bitErrors; nBits=nBits+met.nBits;      % Bit-error accumulation.
    blockErrors=blockErrors+met.blockError;            % Block-error accumulation.
    if met.blockError==0; paySucc=paySucc+met.payloadBits; end     % Payload of CRC-passed blocks.
end
fprintf('AWGN QPSK SISO 30dB: BER=%.3g BLER=%.3g bits/frame=%.0f NMSE=%.2e\n', bitErrors/nBits, blockErrors/cfg.numFrames, paySucc/cfg.numFrames, met.nmse);
if bitErrors==0 && blockErrors==0
    fprintf('END-TO-END CHECK PASS\n');
else
    fprintf('END-TO-END CHECK FAIL\n');
end
