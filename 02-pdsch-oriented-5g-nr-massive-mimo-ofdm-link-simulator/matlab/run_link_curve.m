
%%
function out = run_link_curve(cfg, snrDbVec, numFrames, idealCsi)
%% Shared Link-Level Performance-Curve Engine:
%%
%{
The run_link_curve function executes one complete link-level performance curve over a supplied SNR grid and is the
shared engine of the comparison script. For every SNR point and every Monte Carlo frame the function builds a
transport-block frame with CRC attachment, scrambling, QAM mapping, and DM-RS insertion, draws an independent channel
realization, computes the configured precoder, and applies the effective channel with additive receiver noise at the
fixed total-transmit-SNR level. The channel knowledge supplied to the equalizer is selected by the idealCsi argument:
when true, the true effective channel is passed directly to the equalizer, which is the ideal-CSI reference mode used
to measure the receiver algorithms without estimation error; when false, the least-squares DM-RS estimate is used, so
that the difference between the two modes isolates the channel-estimation loss. The function accumulates the bit
error rate, the CRC-based block error rate, the RMS error vector magnitude, and the channel-estimation NMSE at every
SNR point, returns them as arrays aligned with the SNR grid, and additionally retains the equalized symbol block of
the final frame so that the calling script can draw constellation figures without re-running the chain.

Input:

    cfg                           Complete simulation configuration structure.
    snrDbVec                      SNR grid of the curve in decibels.
    numFrames                     Monte Carlo frames per SNR point.
    idealCsi                      True for the ideal-CSI reference mode, false for LS estimation.

Output:

    out.snrDb                     SNR grid of the curve.
    out.ber                       Bit error rate per SNR point.
    out.bler                      Block error rate per SNR point.
    out.evm                       Average RMS error vector magnitude per SNR point.
    out.nmse                      Average channel-estimation NMSE per SNR point.
    out.capacity                  Average layer-domain capacity reference per SNR point in bit/s/Hz.
    out.shatSample                Equalized symbol block of the final frame, kept for constellation figures.
%}
%% Output arrays over the SNR grid:
%%

nS = numel(snrDbVec);                              % Number of SNR points of the curve.
out.snrDb = snrDbVec(:);                           % SNR grid returned with the results.
out.ber = zeros(nS,1); out.bler = zeros(nS,1);     % Preallocated error-rate arrays.
out.evm = zeros(nS,1); out.nmse = zeros(nS,1);     % Preallocated EVM and NMSE arrays.
out.capacity = zeros(nS,1);                        % Preallocated layer-domain capacity array.
out.shatSample = [];                               % Final-frame symbols kept for constellation figures.


%% Monte Carlo loop:
%%

for s = 1:nS                                       % One SNR point per iteration.
    snrDb = snrDbVec(s);                           % SNR of the current point.
    be=0; nb=0; blk=0; ev=0; nm=0; cp=0;           % Per-point accumulators.
    for f = 1:numFrames                            % One independent frame per iteration.
        frame = build_frame(cfg);                  % Transport block, CRC, scrambling, QAM, layers, and DM-RS.
        H = generate_channel(cfg);                 % One independent channel realization.
        W = compute_precoder(cfg, H);              % Precoder of the current realization.
        [rx, nv] = apply_mimo_channel(frame.layerGrid, H, W, snrDb);   % Channel and receiver noise.
        if idealCsi
            G = true_effective_channel(H, W);      % Ideal-CSI reference mode.
        else
            G = estimate_effective_channel_ls(rx, frame, cfg);         % LS estimation on the DM-RS.
        end
        shat = equalize_mimo(rx, G, frame.dataPositions, nv, cfg);     % Layer symbols on the data elements.
        met = compute_frame_metrics(shat, frame, G, H, W, snrDb, cfg); % Frame-level metric set.
        be = be + met.bitErrors; nb = nb + met.nBits;                  % Bit-error accumulation.
        blk = blk + met.blockError;                % Block-error accumulation.
        ev = ev + met.evm; nm = nm + met.nmse;     % EVM and NMSE accumulation.
        cp = cp + met.capacityBpsHz;               % Capacity accumulation; the value is already computed per
                                                   % frame by compute_frame_metrics, so no random draw is added
                                                   % and every existing result stays bit-identical.
    end
    out.ber(s) = be/nb;                            % Bit error rate of the point.
    out.bler(s) = blk/numFrames;                   % Block error rate of the point.
    out.evm(s) = ev/numFrames;                     % Average RMS EVM of the point.
    out.nmse(s) = nm/numFrames;                    % Average estimation NMSE of the point.
    out.capacity(s) = cp/numFrames;                % Average layer-domain capacity of the point.
    out.shatSample = shat;                         % Final-frame symbols kept for constellation figures.
end
end
