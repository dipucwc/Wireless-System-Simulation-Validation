
%%
 function [rxGrid, noiseVar] = sl_apply_channel(layerGrid, H, W, snrDb)
%% Simulink Channel-Application Wrapper:
%%
%{
The sl_apply_channel function applies the effective channel and adds receiver noise at the fixed total-transmit-SNR
convention for the Simulink testbench, through apply_mimo_channel.

Input:

    layerGrid                     Transmit layer grid of the frame.
    H                             Channel realization.
    W                             Wideband precoder.
    snrDb                         Total transmit SNR in decibels.

Output:

    rxGrid                        Received antenna grid.
    noiseVar                      Complex receiver-noise variance.
%}

[rxGrid, noiseVar] = apply_mimo_channel(layerGrid, H, W, snrDb);   % Channel and noise at the fixed convention.
end
