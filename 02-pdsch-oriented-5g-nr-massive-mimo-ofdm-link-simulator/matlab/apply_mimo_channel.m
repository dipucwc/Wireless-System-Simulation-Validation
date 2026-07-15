
%% 
function [rxGrid, noiseVar] = apply_mimo_channel(layerGrid, H, W, snrDb)
%% MIMO Channel and Receiver-Noise Application:
%%
%{
The apply_mimo_channel function applies the effective downlink channel to the layer-domain resource grid and adds
receiver noise. On every resource element the layer vector is precoded to the antenna domain and multiplied by the
channel matrix of the corresponding subcarrier; the precoder argument is accepted either as one fixed wideband matrix
or as a per-subcarrier array, and the per-subcarrier case is detected by the first dimension matching the subcarrier
count, a test that remains valid when trailing singleton dimensions collapse in the single-layer or single-antenna
cases. The signal-to-noise ratio follows the total-transmit-SNR convention: with unit-power layers and unit-norm
precoder columns, the total transmitted power equals the number of layers, so the per-receive-antenna noise variance
is fixed as the layer count divided by the linear SNR. Because the noise variance is fixed per SNR point and
independent of the channel realization, fading statistics appear correctly in the results and beamforming gain
appears as a genuine bit-error-rate improvement.

Input:

    layerGrid                     Transmit layer grid of size nSymbols x nSC x nLayers.
    H                             Channel realization of size nSC x nRx x nTx.
    W                             Precoder, wideband or per-subcarrier.
    snrDb                         Total transmit SNR in decibels.

Output:

    rxGrid                        Received antenna grid of size nSymbols x nSC x nRx.
    noiseVar                      Complex receiver-noise variance applied per antenna.
%}
%% Dimensions and per-subcarrier precoder detection:
%%

[nsym,nsc,nLayers] = size(layerGrid);              % Dimensions of the transmit layer grid.
nRx = size(H,2);                                   % Receive-antenna count of the channel.
perK = (size(W,1) == nsc);                         % Per-subcarrier precoders are detected by the leading dimension.


%% Noiseless received grid, one matrix product per resource element:
%%

rxNoiseless = complex(zeros(nsym,nsc,nRx));        % Preallocated noiseless received grid.
for m = 1:nsym                                     % One OFDM symbol per iteration.
    for k = 1:nsc                                  % One subcarrier per iteration.
        s = reshape(layerGrid(m,k,:), [], 1);      % Layer vector on this resource element.
        if perK
            Wk = reshape(W(k,:,:), [], nLayers);   % Precoder of this subcarrier.
        else
            Wk = W;                                % One wideband precoder for all subcarriers.
        end
        x = Wk*s;                                  % Antenna-domain transmit vector.
        y = reshape(H(k,:,:), nRx, []) * x;        % Channel application on this subcarrier.
        rxNoiseless(m,k,:) = reshape(y,1,1,nRx);   % Received vector stored on this element.
    end
end


%% Additive receiver noise at the fixed total-transmit-SNR level:
%%

noiseVar = nLayers / 10^(snrDb/10);                % Total transmit power equals the layer count.
noise = sqrt(noiseVar/2)*(randn(size(rxNoiseless))+1j*randn(size(rxNoiseless)));   % Complex Gaussian noise.
rxGrid = rxNoiseless + noise;                      % Received grid with additive receiver noise.
end
