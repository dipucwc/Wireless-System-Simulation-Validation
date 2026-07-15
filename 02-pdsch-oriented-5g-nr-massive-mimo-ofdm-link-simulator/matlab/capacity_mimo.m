
%% 
function C = capacity_mimo(G, snrDb, nLayers)
%% Layer-Domain MIMO Capacity Reference:
%%
%{
The capacity_mimo function evaluates the layer-domain MIMO capacity reference on the true effective channel, as the
base-two log-determinant of the identity plus the Gram matrix of the effective channel scaled by the linear
signal-to-noise ratio with equal power allocation across the layers, computed per subcarrier and averaged over the
grid. The result is the achievable-rate reference bound of the metric set and is never interpreted as achieved coded
throughput.

Input:

    G                             True effective channel of size nSC x nRx x nLayers.
    snrDb                         Total transmit SNR in decibels.
    nLayers                       Number of spatial layers.

Output:

    C                             Layer-domain capacity in bit/s/Hz, averaged over the subcarriers.
%}
%% Per-subcarrier evaluation:
%%

rho = 10^(snrDb/10);                               % Linear signal-to-noise ratio.
[nsc,~,~] = size(G);                               % Subcarrier count of the effective channel.
vals = zeros(nsc,1);                               % Per-subcarrier capacity values.
I = eye(nLayers);                                  % Identity of the layer dimension.
for k = 1:nsc                                      % One subcarrier per iteration.
    Gk = squeeze(G(k,:,:));                        % Effective channel on this subcarrier.
    vals(k) = real(log2(det(I + (rho/nLayers)*(Gk'*Gk))));   % Log-determinant with equal power per layer.
end
C = mean(vals);                                    % Average over the subcarrier grid.
end
