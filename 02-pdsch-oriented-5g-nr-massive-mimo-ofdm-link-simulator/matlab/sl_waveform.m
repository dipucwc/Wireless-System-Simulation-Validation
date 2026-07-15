
%% 
function txWave = sl_waveform(layerGrid, W)
%% Simulink CP-OFDM Waveform Wrapper:
%%
%{
The sl_waveform function builds the precoded antenna-domain resource grid, centers it in the FFT window, and converts
it to the time-domain CP-OFDM waveform through the unitary modulator, feeding the RF measurement branch of the
Simulink testbench. The function is a deterministic mapping of signals already present in the model and consumes no
random numbers, so it changes no simulation result.

Input:

    layerGrid                     Transmit layer grid of the frame.
    W                             Wideband precoder.

Output:

    txWave                        Time-domain CP-OFDM waveform, samples x nTx.
%}

cfg = config();                                    % Locked simulation configuration.
off = (cfg.nFFT - cfg.nSC)/2;                      % Active subcarriers centered in the FFT window.
X = complex(zeros(cfg.nFFT, cfg.nSymbols, cfg.nTx));
for m = 1:cfg.nSymbols
    for k = 1:cfg.nSC
        s = reshape(layerGrid(m,k,:), [], 1);
        X(off+k, m, :) = W*s;                      % Precoded antenna-domain grid entry.
    end
end
txWave = ofdm_modulate(X, cfg);                    % Time-domain CP-OFDM waveform.
end
