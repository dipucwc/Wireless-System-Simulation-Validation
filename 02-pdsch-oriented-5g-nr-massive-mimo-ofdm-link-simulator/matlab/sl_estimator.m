
%%
function Ghat = sl_estimator(rxGrid)
%% Simulink LS-Estimator Wrapper:
%%
%{
The sl_estimator function performs the least-squares estimation on the DM-RS for the Simulink testbench, with time
averaging over the DM-RS symbols and linear frequency interpolation, through estimate_effective_channel_ls. The
deterministic frame layout is rebuilt through sl_layout, so no transmit-side layout signal is required.

Input:

    rxGrid                        Received antenna grid.

Output:

    Ghat                          Estimated effective channel of size nSC x nRx x nLayers.
%}

cfg = config();                                    % Locked simulation configuration.
[dmrsMask, dmrsValues, ~] = sl_layout();           % Deterministic frame layout.
f.dmrsMask = dmrsMask; f.dmrsValues = dmrsValues;  % Minimal frame structure for the estimator.
Ghat = estimate_effective_channel_ls(rxGrid, f, cfg);   % LS estimate on the DM-RS.
end
