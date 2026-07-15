
%% 
function W = sl_precoder(H)
%% Simulink Precoder Wrapper:
%%
%{
The sl_precoder function computes the wideband eigen-beamforming precoder of the Simulink testbench from the supplied
channel realization through compute_precoder.

Input:

    H                             Channel realization of size nSC x nRx x nTx.

Output:

    W                             Wideband precoder of size nTx x nLayers.
%}

cfg = config();                                    % Locked simulation configuration.
W = compute_precoder(cfg, H);                      % Wideband eigen-beamforming precoder.
end
