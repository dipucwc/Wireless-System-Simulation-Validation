
%% 
function G = true_effective_channel(H, W)
%% True Effective Layer Channel:
%%
%{
The true_effective_channel function computes the exact effective layer channel as the per-subcarrier product of the
physical channel matrix and the precoder. The precoder is accepted either as one fixed wideband matrix or as a
per-subcarrier array, detected by the first dimension matching the subcarrier count, with the layer count recovered
from the element count in the per-subcarrier case so that the detection remains valid when trailing singleton
dimensions collapse. The result is used as the ideal-CSI reference for the equalizer, as the ground truth of the
channel-estimation NMSE, and as the input of the layer-domain capacity reference.

Input:

    H                             Physical channel of size nSC x nRx x nTx.
    W                             Precoder, wideband nTx x nLayers or per-subcarrier nSC x nTx x nLayers.

Output:

    G                             True effective channel of size nSC x nRx x nLayers.
%}
%% Dimensions and precoder detection:
%%

[nsc,nRx,nTx] = size(H);                           % Dimensions of the physical channel.
perK = (size(W,1) == nsc);                         % Per-subcarrier precoders are detected by the leading dimension.
if perK
    nLayers = numel(W) / (nsc*nTx);                % Recover the layer count when singleton dimensions collapse.
else
    nLayers = size(W,2);                           % Wideband precoder carries the layer count directly.
end


%% Per-subcarrier effective channel:
%%

G = complex(zeros(nsc,nRx,nLayers));               % Preallocated effective channel.
for k = 1:nsc                                      % One subcarrier per iteration.
    if perK
        Wk = reshape(W(k,:,:), nTx, nLayers);      % Precoder of this subcarrier.
    else
        Wk = W;                                    % One wideband precoder for all subcarriers.
    end
    G(k,:,:) = reshape(H(k,:,:), nRx, nTx) * Wk;   % Effective channel as the channel-precoder product.
end
end
