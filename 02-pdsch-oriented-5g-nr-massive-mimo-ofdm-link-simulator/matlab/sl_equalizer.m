
%%
function shat = sl_equalizer(rxGrid, Ghat, noiseVar)
%% Simulink Equalizer Wrapper:
%%
%{
The sl_equalizer function recovers the layer symbols on every data resource element for the Simulink testbench,
applying the zero-forcing or unbiased MMSE equalizer selected in the configuration through equalize_mimo. The data
positions are rebuilt through the deterministic sl_layout.

Input:

    rxGrid                        Received antenna grid.
    Ghat                          Effective-channel estimate.
    noiseVar                      Complex receiver-noise variance.

Output:

    shat                          Equalized layer symbols, one row per data resource element.
%}

cfg = config();                                    % Locked simulation configuration.
[~, ~, dataPositions] = sl_layout();               % Deterministic data positions.
shat = equalize_mimo(rxGrid, Ghat, dataPositions, noiseVar, cfg);   % Configured ZF or MMSE equalizer.
end
