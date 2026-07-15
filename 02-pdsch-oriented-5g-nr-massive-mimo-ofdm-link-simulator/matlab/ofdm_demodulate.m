
%%
function grid = ofdm_demodulate(waveform, cfg, nTx)
%% CP-OFDM Demodulator:
%%
%{
The ofdm_demodulate function converts the time-domain CP-OFDM waveform back to the frequency-domain resource grid as
the exact inverse of the modulator. For every OFDM symbol the cyclic prefix is discarded, the remaining samples are
transformed with the FFT scaled by the inverse square root of the FFT size, and the spectrum is shifted so that the
active subcarriers are again centered; the round trip through the modulator and this function is confirmed at machine
precision by verification gate three.

Input:

    waveform                      Time-domain CP-OFDM waveform, samples x nTx.
    cfg.nFFT                      FFT size of the OFDM grid.
    cfg.nSymbols                  Number of OFDM symbols per slot.
    nTx                           Number of antenna streams in the waveform.

Output:

    grid                          Frequency-domain grid of size nFFT x nSymbols x nTx, subcarriers centered.
%}
%% Dimensions and cyclic-prefix length:
%%

cpLen = round(cfg.nFFT/14);                        % Must match the modulator cyclic-prefix length.
symLen = cfg.nFFT + cpLen;                         % Samples per OFDM symbol including the prefix.


%% Per-symbol CP removal and FFT:
%%

grid = complex(zeros(cfg.nFFT,cfg.nSymbols,nTx));  % Preallocated frequency-domain output grid.
for m = 1:cfg.nSymbols                             % One OFDM symbol per iteration.
    idx = (m-1)*symLen + cpLen + (1:cfg.nFFT);     % Sample range of the symbol body after the prefix.
    x = waveform(idx,:);                           % Symbol-body samples of all antenna streams.
    grid(:,m,:) = fftshift(fft(x,cfg.nFFT,1)/sqrt(cfg.nFFT),1);   % Unitary transform with centered spectrum.
end
end
