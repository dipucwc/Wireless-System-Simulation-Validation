
%%
function [bitErrors, nBits, blockError, evm, nmse, capacity] = sl_metrics(shat, layerGrid, bitsCrc, Ghat, H, W, snrDb)
%% Simulink Metric Wrapper:
%%
%{
The sl_metrics function performs the demapping, descrambling, CRC decision, and metric calculation of the Simulink
testbench through compute_frame_metrics, reconstructing the minimal frame structure from the transmit-side reference
signals and the deterministic layout.

Input:

    shat                          Equalized layer symbols.
    layerGrid                     Transmit layer grid of the frame, reference symbols.
    bitsCrc                       CRC-attached transmit bit sequence.
    Ghat                          Effective-channel estimate.
    H                             Channel realization.
    W                             Wideband precoder.
    snrDb                         Total transmit SNR in decibels.

Output:

    bitErrors                     Detected-bit errors of the frame.
    nBits                         Evaluated payload bits of the frame.
    blockError                    One when the CRC decision fails, zero otherwise.
    evm                           Normalized RMS error vector magnitude.
    nmse                          Effective-channel estimation NMSE.
    capacity                      Layer-domain capacity reference in bit/s/Hz.
%}

cfg = config();                                    % Locked simulation configuration.
[~, ~, dataPositions] = sl_layout();               % Deterministic data positions.
f.bitsCrc = uint8(bitsCrc(:));                     % Reference CRC-attached bits.
f.payload = uint8(bitsCrc(1:end-cfg.crcLen));      % Reference payload bits.
f.layerGrid = layerGrid;                           % Reference transmit symbols.
f.dataPositions = dataPositions;                   % Data positions of the frame.
met = compute_frame_metrics(shat, f, Ghat, H, W, snrDb, cfg);   % Complete frame metric set.
bitErrors = met.bitErrors; nBits = met.nBits; blockError = met.blockError;   % Scalar outputs.
evm = met.evm; nmse = met.nmse; capacity = met.capacityBpsHz;                % Scalar outputs.
end
