
%%
%% run_ldpc_campaign
%% LDPC-Coded PDSCH Campaign on the Verified Link-Level Chain:
%%
%{
The run_ldpc_campaign script executes the LDPC-coded transport-block campaign on the compact verification
configuration. The physical-layer chain is the verified chain of the package: the channel generation, the wideband
precoder, the channel and noise application, the least-squares DM-RS channel estimation, and the linear MIMO
equalization are the identical functions used by the uncoded reference results, and none of them is modified. The
transport-channel processing wraps this verified chain with the 3GPP-conformant downlink shared-channel coding of the
5G Toolbox: CRC attachment, code-block segmentation, LDPC encoding on the standard base graphs, and rate matching are
performed by the nrDLSCH encoder, and the receiver performs rate recovery and iterative LDPC decoding with the
nrDLSCHDecoder object per TS 38.212.

The bit-to-symbol mapping of this coded campaign uses nrSymbolModulate and nrSymbolDemodulate rather than the
package's own qam_modulate and qam_demodulate_hard. The reason is deliberate: the LDPC decoder consumes soft
log-likelihood ratios whose bit ordering and sign convention must match the TS 38.211 constellation exactly, and the
Toolbox modulator and demodulator guarantee that consistency by construction, which removes the entire class of
constellation-mapping and LLR-polarity integration faults. The verified custom mapping remains the reference of the
uncoded chain; the coded campaign is 3GPP-conformant end to end in its transport and modulation processing.

The soft equalizer of this script duplicates the arithmetic of the verified equalize_mimo function and additionally
returns the per-resource-element, per-layer effective noise variance of the unbiased equalizer output, which the
soft demodulator requires for the LLR scaling. The verified equalize_mimo file itself is not touched.

Three verification gates run before the campaign and abort the script on any failure. Gate L1 passes one coded
transport block through encoding, scrambling, modulation, noiseless demodulation, descrambling, and decoding, and
requires an error-free round trip with a passing CRC. Gate L2 confirms the log-likelihood-ratio sign convention of
the Toolbox demodulator against the scrambling sequence handling of this script. Gate L3 runs one complete coded
frame through the full verified chain at a high signal-to-noise ratio and requires a passing block.

Outputs follow the package conventions: one CSV result file with one row per code rate and SNR point, a configuration
log written beside it, and the coded block-error-rate and throughput figures in the house style, with the uncoded
reference curves of the compact run overlaid when the uncoded CSV is present.

Set smokeTest to true for a fast pipeline validation with few frames, and to false for the full campaign.
%}
%% Run control:
%%

clear;
clc;
close all;

addpath(genpath(pwd));                             % Add the project directory and all subdirectories to the path.

smokeTest = false;                                 % True: 4 frames/point for pipeline validation. False: full run.

cfg = config('compact');                           % Locked compact verification configuration; chain unchanged.

cfg.snrDb = 0:2.5:15;                              % Fine grid over the waterfall region of all three rates; the
                                                   % locked chain, seed, and geometry are unchanged by this override.

rng(cfg.randomSeed);                               % Fixed seed for a reproducible coded Monte Carlo run.

targetRates = [308 490 772] / 1024;                % Target code rates of the campaign, MCS-table style values
                                                   % approximately 0.30, 0.48, and 0.75, TS 38.214 form R*1024.

if smokeTest
    numFrames = 4;                                 % Smoke-test frame count per SNR point.
else
    numFrames = 100;                               % Fine-grid campaign block count per SNR point; one hundred
                                                   % blocks give a BLER resolution of 0.01 and bound a
                                                   % zero-observed-error point below 0.03 at 95 percent confidence.
end

ldpcAlgorithm = 'Normalized min-sum';              % Decoder algorithm; min-sum for practical run time.
ldpcMaxIterations = 20;                            % Iteration cap of the LDPC decoder.
rv = 0;                                            % Single transmission, redundancy version zero, no HARQ.

outCsvRel = '../04_Simulation_Results/MATLAB/csv/matlab_results_ldpc_fine.csv';   % Fine-grid result file; the
                                                   % executed 5 dB grid campaign keeps its own separate CSV.
uncodedCsvRel = cfg.outputCsv;                     % Uncoded compact reference CSV for the overlay curves.


%% Grid geometry shared with the verified chain:
%%
%  The DM-RS mask and the data-position list are reproduced exactly as build_frame constructs them, so the coded
%  frames occupy the identical resource elements and the verified estimator and equalizer see the identical layout.

dmrsMask = false(cfg.nSymbols, cfg.nSC, cfg.nLayers);          % Pilot position mask per layer.
for m = cfg.dmrsSymbols
    for layer = 1:cfg.nLayers
        dmrsMask(m, layer:cfg.dmrsSpacing:cfg.nSC, layer) = true;
    end
end
pilotAny = any(dmrsMask,3);                        % Resource elements used by any layer's pilots.
dataMask = ~pilotAny;                              % Remaining elements carry data on all layers.
[mIdx,kIdx] = find(dataMask);
dataPositions = [mIdx kIdx];                       % Data positions in the transmitter order.
nDataRE = size(dataPositions,1);                   % Data resource elements per slot.

G = nDataRE * cfg.nLayers * cfg.bitsPerSymbol;     % Coded-bit budget carried by the grid, the rate-matching length.

nPRB = cfg.nSC / 12;                               % Physical resource blocks of the grid.
nREPerPRB = nDataRE / nPRB;                        % Data resource elements per PRB, the nrTBS capacity input.

dmrsValues = complex(zeros(cfg.nSymbols, cfg.nSC, cfg.nLayers));   % Deterministic pilots, identical to build_frame.
for layer = 1:cfg.nLayers
    [mp,kp] = find(dmrsMask(:,:,layer));
    nPil = length(mp);
    cInit = bitshift(uint32(cfg.nID),8) + uint32(layer);
    c = nr_gold_sequence(cInit, 2*nPil);
    pil = (1-2*double(c(1:2:end)) + 1j*(1-2*double(c(2:2:end))))/sqrt(2);
    for p = 1:nPil
        dmrsValues(mp(p),kp(p),layer) = pil(p);
    end
end

geom.dmrsMask = dmrsMask;                          % Geometry bundle consumed by the local frame builder.
geom.dmrsValues = dmrsValues;
geom.dataMask = dataMask;
geom.dataPositions = dataPositions;
geom.nDataRE = nDataRE;

scramInit = bitshift(uint32(cfg.rnti),15) + uint32(cfg.nID);   % Scrambling initialization, identical to scramble_bits.
scramSeq = nr_gold_sequence(scramInit, G);         % Fixed scrambling sequence of the coded-bit budget.
llrSign = 1 - 2*double(scramSeq(:));               % LLR descrambling sign per coded bit position.


%% Transport-block sizes per target rate:
%%

nRates = numel(targetRates);
tbsPerRate = zeros(nRates,1);
for r = 1:nRates
    tbsPerRate(r) = nrTBS(cfg.modulation, cfg.nLayers, nPRB, nREPerPRB, targetRates(r));   % TS 38.214 TBS.
end


%% Verification gates:
%%

fprintf('--- LDPC campaign verification gates ---\n');

% Gate L1: noiseless coded round trip through encode, scramble, modulate, demodulate, descramble, decode.
encL1 = nrDLSCH('TargetCodeRate', targetRates(2));
decL1 = nrDLSCHDecoder('TargetCodeRate', targetRates(2), 'TransportBlockLength', tbsPerRate(2), ...
    'LDPCDecodingAlgorithm', ldpcAlgorithm, 'MaximumLDPCIterationCount', ldpcMaxIterations);
tbL1 = randi([0 1], tbsPerRate(2), 1, 'int8');
setTransportBlock(encL1, tbL1);
codedL1 = encL1(cfg.modulation, cfg.nLayers, G, rv);
scrL1 = xor(logical(codedL1), logical(scramSeq(:)));
symL1 = nrSymbolModulate(double(scrL1), cfg.modulation);
llrL1 = nrSymbolDemodulate(symL1, cfg.modulation, 1e-4);       % Near-noiseless soft demodulation.
llrL1 = llrL1 .* llrSign;                          % Sign-flip descrambling in the LLR domain.
[decL1bits, blkerrL1] = decL1(llrL1, cfg.modulation, cfg.nLayers, rv);
assert(~blkerrL1 && isequal(decL1bits, tbL1), 'Gate L1 FAIL: noiseless coded round trip');
fprintf('Gate L1 PASS: noiseless coded round trip error-free, CRC pass\n');

% Gate L2: LLR sign convention; a positive log-likelihood ratio must correspond to bit zero.
probeBits = int8([0;0;0;0]);                       % One 16-QAM symbol of known zero bits.
probeSym = nrSymbolModulate(double(probeBits), cfg.modulation);
probeLlr = nrSymbolDemodulate(probeSym, cfg.modulation, 1e-4);
assert(all(probeLlr > 0), 'Gate L2 FAIL: LLR sign convention');
fprintf('Gate L2 PASS: positive LLR corresponds to bit zero\n');

% Gate L3: one complete coded frame through the full verified chain at high SNR, block must pass.
reset(decL1);
setTransportBlock(encL1, tbL1);
codedL3 = encL1(cfg.modulation, cfg.nLayers, G, rv);
frameL3 = build_frame_from_coded_bits(codedL3, scramSeq, geom, cfg);
H3 = generate_channel(cfg);
W3 = compute_precoder(cfg, H3);
[rx3, nv3] = apply_mimo_channel(frameL3.layerGrid, H3, W3, 30);            % High-SNR single frame.
G3 = estimate_effective_channel_ls(rx3, frameL3, cfg);
[shat3, nvEff3] = equalize_mimo_soft(rx3, G3, geom.dataPositions, nv3, cfg);
llr3 = demodulate_llr(shat3, nvEff3, cfg) .* llrSign;
[~, blkerrL3] = decL1(llr3, cfg.modulation, cfg.nLayers, rv);
assert(~blkerrL3, 'Gate L3 FAIL: full-chain coded frame at 30 dB');
fprintf('Gate L3 PASS: full verified chain, coded block decoded at 30 dB\n');
fprintf('--- All gates passed; campaign may run ---\n');


%% Coded Monte Carlo campaign over rates and the SNR grid:
%%

rows = [];                                         % One result row per rate and SNR point.

for r = 1:nRates
    R = targetRates(r);
    tbs = tbsPerRate(r);

    encDL = nrDLSCH('TargetCodeRate', R);          % Encoder of this rate.
    decDL = nrDLSCHDecoder('TargetCodeRate', R, 'TransportBlockLength', tbs, ...
        'LDPCDecodingAlgorithm', ldpcAlgorithm, 'MaximumLDPCIterationCount', ldpcMaxIterations);

    for isnr = 1:length(cfg.snrDb)
        snrDb = cfg.snrDb(isnr);

        bitErrors = 0; nBits = 0; blockErrors = 0; payloadSuccess = 0;

        for f = 1:numFrames
            tb = randi([0 1], tbs, 1, 'int8');     % Transport-block payload of this frame.
            setTransportBlock(encDL, tb);
            codedBits = encDL(cfg.modulation, cfg.nLayers, G, rv);         % CRC, segmentation, LDPC, rate matching.

            frame = build_frame_from_coded_bits(codedBits, scramSeq, geom, cfg);   % Scramble, modulate, map, pilots.

            H = generate_channel(cfg);             % Verified chain from here to the equalizer output.
            W = compute_precoder(cfg, H);
            [rx, nv] = apply_mimo_channel(frame.layerGrid, H, W, snrDb);
            Ghat = estimate_effective_channel_ls(rx, frame, cfg);
            [shat, nvEff] = equalize_mimo_soft(rx, Ghat, geom.dataPositions, nv, cfg);

            llr = demodulate_llr(shat, nvEff, cfg) .* llrSign;             % Soft demapping and LLR descrambling.

            reset(decDL);                          % Single transmission per frame; clear the soft buffer.
            [decBits, blkerr] = decDL(llr, cfg.modulation, cfg.nLayers, rv);

            bitErrors = bitErrors + sum(decBits ~= tb);
            nBits = nBits + tbs;
            blockErrors = blockErrors + double(blkerr);
            if ~blkerr
                payloadSuccess = payloadSuccess + tbs;                     % Delivered bits of CRC-passed blocks.
            end
        end

        row.snrDb = snrDb;
        row.targetCodeRate = R;
        row.tbs = tbs;
        row.effCodeRate = tbs / G;                 % Delivered information rate against the coded-bit budget.
        row.ber = bitErrors / nBits;
        row.bler = blockErrors / numFrames;
        row.throughputMbps = (payloadSuccess/numFrames) / cfg.slotDurationS / 1e6;
        row.spectralEffBpsHz = row.throughputMbps*1e6 / (cfg.nSC*cfg.subcarrierSpacingHz);
        row.numFrames = numFrames;
        row.nTx = cfg.nTx; row.nRx = cfg.nRx; row.nLayers = cfg.nLayers;
        rows = [rows; row]; %#ok<AGROW>

        fprintf('R=%.4f  %3d dB  BLER %.3f  BER %.3e  Thpt %.3f Mbit/s\n', ...
            R, snrDb, row.bler, row.ber, row.throughputMbps);
    end
end

T = struct2table(rows);


%% CSV result file and configuration log:
%%

outCsv = fullfile(pwd, outCsvRel);
[folder,~,~] = fileparts(outCsv);
if ~exist(folder,'dir'), mkdir(folder); end
writetable(T, outCsv);
fprintf('Saved LDPC campaign CSV: %s\n', outCsv);

cfgLog = cfg;                                      % Campaign parameters appended to the archived configuration.
cfgLog.ldpcTargetRates = targetRates;
cfgLog.ldpcTbs = tbsPerRate(:).';
cfgLog.ldpcAlgorithm = ldpcAlgorithm;
cfgLog.ldpcMaxIterations = ldpcMaxIterations;
cfgLog.ldpcRv = rv;
cfgLog.ldpcNumFrames = numFrames;
cfgLog.ldpcSmokeTest = smokeTest;
cfgLog.ldpcCodedBitBudget = G;
write_config_log(cfgLog, outCsv);


%% Uncoded reference curves for the overlay:
%%

uncoded = [];
uncodedCsv = fullfile(pwd, uncodedCsvRel);
if exist(uncodedCsv,'file')
    uncoded = readtable(uncodedCsv);               % Executed uncoded compact results, never re-typed by hand.
else
    fprintf('Uncoded reference CSV not found; figures drawn without the overlay.\n');
end


%% Figure preparation:
%%

figDir = fullfile(pwd, cfg.outputFigDir);
if ~exist(figDir,'dir'), mkdir(figDir); end

cfgStr = sprintf('%s, %dx%d, L = %d, %s, %s', upper(cfg.modulation), cfg.nTx, cfg.nRx, ...
    cfg.nLayers, upper(cfg.channelModel), upper(cfg.equalizer));


%% Coded BLER figure with the uncoded reference:
%%

figure(18);
hold on;
for r = 1:nRates
    Tr = T(abs(T.targetCodeRate - targetRates(r)) < 1e-9, :);
    y = Tr.bler; y(y==0) = NaN;                    % Zero-error points hidden on the logarithmic axis.
    semilogy(Tr.snrDb, y, '-o', 'LineWidth', 1.2, ...
        'DisplayName', sprintf('LDPC, R = %.2f', targetRates(r)));
end
if ~isempty(uncoded)
    yU = uncoded.bler; yU(yU==0) = NaN;
    semilogy(uncoded.snrDb, yU, '--s', 'LineWidth', 1.2, 'DisplayName', 'Uncoded reference');
end
set(gca,'YScale','log');
grid on;
xlabel('Total transmit SNR (dB)');
ylabel('BLER');
title({'LDPC-Coded Block Error Rate vs SNR'; cfgStr});
legend('Location','southwest');
hold off;
saveas(figure(18), fullfile(figDir,'bler_ldpc_fine_vs_snr.png'));


%% Coded throughput figure with the uncoded reference:
%%

figure(19);
hold on;
for r = 1:nRates
    Tr = T(abs(T.targetCodeRate - targetRates(r)) < 1e-9, :);
    plot(Tr.snrDb, Tr.throughputMbps, '-o', 'LineWidth', 1.2, ...
        'DisplayName', sprintf('LDPC, R = %.2f', targetRates(r)));
end
if ~isempty(uncoded)
    plot(uncoded.snrDb, uncoded.throughputMbps, '--s', 'LineWidth', 1.2, ...
        'DisplayName', 'Uncoded reference');
end
grid on;
xlabel('Total transmit SNR (dB)');
ylabel('Throughput (Mbit/s)');
title({'LDPC-Coded Throughput vs SNR'; cfgStr});
legend('Location','northwest');
hold off;
saveas(figure(19), fullfile(figDir,'throughput_ldpc_fine_vs_snr.png'));

fprintf('Saved figures to: %s\n', figDir);


%% Local functions:
%%

function frame = build_frame_from_coded_bits(codedBits, scramSeq, geom, cfg)
%% Coded-Frame Construction on the Verified Grid Geometry:
%%
%{
The build_frame_from_coded_bits function mirrors the verified build_frame mapping while accepting an externally
encoded bit sequence instead of generating an uncoded payload. The coded bits are scrambled with the identical Gold
sequence, mapped to TS 38.211 constellation symbols by nrSymbolModulate, written into the layer grid in the
resource-element-first, layer-second transmitter order, and completed with the identical deterministic DM-RS values,
so the returned frame structure is consumed by the verified estimator and equalizer without any modification.
%}
scrambled = xor(logical(codedBits(:)), logical(scramSeq(:)));  % Gold-sequence scrambling of the coded block.
qamSymbols = nrSymbolModulate(double(scrambled), cfg.modulation);          % TS 38.211 unit-power symbols.

layerGrid = complex(zeros(cfg.nSymbols, cfg.nSC, cfg.nLayers));
qidx = 1;
for p = 1:geom.nDataRE
    m = geom.dataPositions(p,1); k = geom.dataPositions(p,2);
    layerGrid(m,k,:) = reshape(qamSymbols(qidx:qidx+cfg.nLayers-1),1,1,[]);
    qidx = qidx + cfg.nLayers;
end
for layer = 1:cfg.nLayers
    [mp,kp] = find(geom.dmrsMask(:,:,layer));
    for p = 1:length(mp)
        layerGrid(mp(p),kp(p),layer) = geom.dmrsValues(mp(p),kp(p),layer);
    end
end

frame.layerGrid = layerGrid;                       % Fields consumed by the verified receiver functions.
frame.dmrsMask = geom.dmrsMask;
frame.dmrsValues = geom.dmrsValues;
frame.dataMask = geom.dataMask;
frame.dataPositions = geom.dataPositions;
end


function [shat, nvEff] = equalize_mimo_soft(rxGrid, Ghat, dataPositions, noiseVar, cfg)
%% Soft-Output Linear MIMO Equalization:
%%
%{
The equalize_mimo_soft function duplicates the arithmetic of the verified equalize_mimo function and additionally
returns the per-resource-element, per-layer effective noise variance of the equalizer output that the soft
demodulator requires. In the MMSE branch the unbiased output of layer l has the classical post-equalization
signal-to-interference-plus-noise ratio d/(1-d) with d the diagonal bias factor, so the effective noise variance of
the unit-power symbol is (1-d)/d. In the zero-forcing branch the output noise variance is the receiver noise variance
scaled by the corresponding diagonal element of the pseudo-inverse Gram product. The verified equalize_mimo file is
not modified by this campaign.
%}
nData = size(dataPositions,1);
shat = complex(zeros(nData, cfg.nLayers));
nvEff = zeros(nData, cfg.nLayers);
I = eye(cfg.nLayers);
for p = 1:nData
    m = dataPositions(p,1); k = dataPositions(p,2);
    Gk = squeeze(Ghat(k,:,:));
    y = squeeze(rxGrid(m,k,:));
    if strcmpi(cfg.equalizer,'zf')
        Weq = pinv(Gk);
        shat(p,:) = (Weq*y).';
        nvEff(p,:) = noiseVar * real(diag(Weq*Weq')).';
    else
        Weq = (Gk'*Gk + noiseVar*I) \ Gk';
        d = real(diag(Weq*Gk));
        z = Weq*y;
        d = min(max(d, eps), 1-eps);               % Bias factor clamped to the open unit interval.
        shat(p,:) = (z ./ d).';
        nvEff(p,:) = ((1-d) ./ d).';               % Effective noise variance of the unbiased output.
    end
end
end


function llr = demodulate_llr(shat, nvEff, cfg)
%% Soft Demapping in the Transmitter Bit Order:
%%
%{
The demodulate_llr function produces the log-likelihood ratios of all coded bits in the identical
resource-element-first, layer-second order used by the transmitter. The equalized symbols are demodulated by
nrSymbolDemodulate at unit noise variance, and each symbol's group of bit ratios is then divided by that symbol's
effective noise variance, which is the exact scaling of the max-log ratio. The output sign convention is the Toolbox
convention in which a positive ratio corresponds to bit zero, verified by Gate L2.
%}
symOrdered = reshape(shat.', [], 1);               % Transmit order: layers within each resource element.
nvOrdered = reshape(nvEff.', [], 1);               % Matching effective noise variance per symbol.
llrUnit = nrSymbolDemodulate(symOrdered, cfg.modulation, 1);   % Unit-variance soft demodulation.
llr = llrUnit ./ repelem(nvOrdered, cfg.bitsPerSymbol);        % Exact max-log scaling per symbol.
end
