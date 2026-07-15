
%%
function Ghat = estimate_effective_channel_ls(rxGrid, frame, cfg)
%% Least-Squares Effective-Channel Estimation on the DM-RS:
%%
%{
The estimate_effective_channel_ls function performs least-squares channel estimation on the DM-RS. Because the DM-RS
is precoded together with the data, the estimated quantity is the effective layer channel. For every layer and every
receive antenna the function divides each pilot observation by its known transmitted DM-RS value, averages the
estimates over the DM-RS symbols of the slot, which reduces the pilot noise by three decibels for two symbols, and
linearly interpolates the real and imaginary parts over the subcarrier axis to produce an estimate on every
subcarrier of the grid. The interpolation is valid because the wideband precoder keeps the effective channel as
smooth in frequency as the physical channel.

Input:

    rxGrid                        Received antenna grid of size nSymbols x nSC x nRx.
    frame.dmrsMask                Logical DM-RS position mask per layer.
    frame.dmrsValues              Known transmitted DM-RS values per layer.
    cfg.dmrsSymbols               DM-RS symbol indices within the slot.
    cfg.nLayers                   Number of spatial layers.

Output:

    Ghat                          Estimated effective channel of size nSC x nRx x nLayers.
%}
%% Dimensions:
%%

dmrsMask = frame.dmrsMask;                         % DM-RS position mask per layer.
[~,nsc,nRx] = size(rxGrid);                        % Subcarrier and receive-antenna counts.
Ghat = complex(zeros(nsc,nRx,cfg.nLayers));        % Preallocated effective-channel estimate.
allK = 1:nsc;                                      % Full subcarrier axis for the interpolation.


%% Per-layer, per-receive-antenna LS with time averaging and interpolation:
%%

for layer = 1:cfg.nLayers                          % One layer per iteration.
    [~,pilotK] = find(dmrsMask(:,:,layer));        % All pilot subcarrier occurrences of this layer.
    uniqueK = unique(pilotK).';                    % Comb subcarrier positions of this layer's pilots.
    for r = 1:nRx                                  % One receive antenna per iteration.
        yavg = complex(zeros(size(uniqueK)));      % Time-averaged LS estimate per comb position.
        for idx = 1:length(uniqueK)
            k = uniqueK(idx); vals = [];           % Pilot observations of this comb position.
            for m = cfg.dmrsSymbols
                if dmrsMask(m,k,layer)
                    vals = [vals; rxGrid(m,k,r)/frame.dmrsValues(m,k,layer)]; %#ok<AGROW>   % LS division by the pilot.
                end
            end
            yavg(idx) = mean(vals);                % Averaging over the DM-RS symbols reduces pilot noise.
        end
        re = interp1(uniqueK, real(yavg), allK, 'linear', 'extrap');   % Linear interpolation of the real part.
        im = interp1(uniqueK, imag(yavg), allK, 'linear', 'extrap');   % Linear interpolation of the imaginary part.
        Ghat(:,r,layer) = re(:) + 1j*im(:);        % Estimate on every subcarrier of the grid.
    end
end
end
