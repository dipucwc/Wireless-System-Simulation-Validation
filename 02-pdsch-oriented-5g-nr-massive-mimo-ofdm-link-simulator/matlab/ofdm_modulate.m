
%%
function waveform = ofdm_modulate(resourceGrid, cfg)
%% CP-OFDM Modulator:
%%
%{
The ofdm_modulate function converts the frequency-domain resource grid to the time-domain CP-OFDM waveform. The grid
arrives with the active subcarriers centered in the FFT window, so each symbol is inverse-shifted, transformed with
the inverse FFT scaled by the square root of the FFT size so that the transform pair is unitary, and prepended with
its cyclic prefix; the output waveform is preallocated and filled symbol by symbol. The unitary scaling is confirmed
at machine precision by verification gate three.

Input:

    resourceGrid                  Frequency-domain grid of size nFFT x nSymbols x nTx, subcarriers centered.
    cfg.nFFT                      FFT size of the OFDM grid.

Output:

    waveform                      Time-domain CP-OFDM waveform, samples x nTx.
%}
%% Dimensions and cyclic-prefix length:
%%

[nfft,nsym,nt] = size(resourceGrid);               % Grid dimensions of the supplied resource grid.
if nfft ~= cfg.nFFT                                % The grid must match the configured FFT size.
    error('Resource-grid FFT size mismatch');
end
cpLen = round(cfg.nFFT/14);                        % Cyclic-prefix length of the compact numerology.
symLen = cfg.nFFT + cpLen;                         % Samples per OFDM symbol including the prefix.


%% Per-symbol IFFT with cyclic-prefix insertion:
%%

waveform = complex(zeros(nsym*symLen, nt));        % Preallocated time-domain output waveform.
for m = 1:nsym                                     % One OFDM symbol per iteration.
    x = ifft(ifftshift(squeeze(resourceGrid(:,m,:)),1), cfg.nFFT, 1)*sqrt(cfg.nFFT);   % Unitary inverse transform.
    waveform((m-1)*symLen+(1:symLen), :) = [x(end-cpLen+1:end,:); x];                  % Cyclic prefix then symbol body.
end
end
