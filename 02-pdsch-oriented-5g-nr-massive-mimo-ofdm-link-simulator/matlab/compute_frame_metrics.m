
%%
function met = compute_frame_metrics(shat, frame, Ghat, H, W, snrDb, cfg)
%% Frame-Level Link Metric Calculation:
%%
%{
The compute_frame_metrics function evaluates the per-frame link metrics of the simulator metric set. It first
reconstructs the transmitted reference symbols in the same resource-element-first, layer-second order used by the
transmitter, then demaps the equalized symbols, descrambles them with the same Gold sequence, and compares the
recovered payload with the transmitted payload to obtain the bit error count. The block-error decision is taken from
the CRC24A check over the recovered block. The RMS error vector magnitude is computed over all equalized data symbols
against the transmitted references. The channel-estimation NMSE is computed against the true effective channel, and
the layer-domain capacity reference is evaluated on the same true effective channel, so that the capacity bound
always reflects the channel actually used by the frame.

Auxiliary functions:

    qam_demodulate_hard           Hard demapping of the equalized symbols to bits.
    scramble_bits                 Descrambling with the identical Gold sequence.
    check_crc24a                  CRC24A verification of the recovered block.
    true_effective_channel        True effective channel used as ground truth.
    capacity_mimo                 Layer-domain capacity reference on the true effective channel.

Input:

    shat                          Equalized layer symbols, one row per data resource element.
    frame                         Transmit frame structure with payload, bit sequences, grid, and positions.
    Ghat                          Effective-channel estimate.
    H                             Physical channel realization.
    W                             Precoder used by the frame.
    snrDb                         Total transmit SNR in decibels.
    cfg                           Complete simulation configuration structure.

Output:

    met.bitErrors                 Number of detected-bit errors of the frame.
    met.nBits                     Number of evaluated payload bits.
    met.blockError                One when the recovered CRC decision fails, zero otherwise.
    met.evm                       Normalized RMS error vector magnitude of the frame.
    met.nmse                      Effective-channel estimation NMSE of the frame.
    met.capacityBpsHz             Layer-domain capacity reference of the frame.
    met.payloadBits               Number of payload bits carried by the frame.
%}
%% Reference transmitted symbols in the transmitter ordering:
%%

txSymbols = complex(zeros(size(shat)));            % Transmitted reference symbols of the data elements.
for p = 1:size(frame.dataPositions,1)              % One data resource element per iteration.
    m = frame.dataPositions(p,1); k = frame.dataPositions(p,2);            % Position of this element.
    txSymbols(p,:) = squeeze(frame.layerGrid(m,k,:)).';        % Reference layer symbols of this element.
end


%% Demapping, descrambling, and bit-level comparison:
%%

rxBitsScrambled = qam_demodulate_hard(reshape(shat.',[],1), cfg.modulation);   % Hard demapping in transmit order.
rxBits = scramble_bits(rxBitsScrambled, cfg);      % Descrambling applies the identical exclusive-or sequence.
rxBitsCrc = rxBits(1:length(frame.bitsCrc));       % Recovered CRC-attached block.
rxPayload = rxBitsCrc(1:end-cfg.crcLen);           % Recovered payload portion.
met.bitErrors = sum(rxPayload ~= frame.payload);   % Detected-bit errors of the frame.
met.nBits = length(frame.payload);                 % Evaluated payload bits of the frame.


%% Block error from the CRC decision:
%%

met.blockError = double(~check_crc24a(rxBitsCrc, cfg));        % One when the recovered CRC fails.


%% RMS error vector magnitude over all equalized data symbols:
%%

met.evm = sqrt(mean(abs(shat(:)-txSymbols(:)).^2) / mean(abs(txSymbols(:)).^2));   % Normalized RMS EVM.


%% Channel-estimation NMSE against the true effective channel:
%%

Gtrue = true_effective_channel(H, W);              % Ground-truth effective channel of the frame.
met.nmse = sum(abs(Ghat(:)-Gtrue(:)).^2) / sum(abs(Gtrue(:)).^2);   % Estimation NMSE of the frame.


%% Layer-domain capacity reference on the true effective channel:
%%

met.capacityBpsHz = capacity_mimo(Gtrue, snrDb, cfg.nLayers);  % Capacity bound of the frame channel.
met.payloadBits = length(frame.payload);           % Payload bits carried by the frame.
end
