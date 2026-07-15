
%% 
function shat = equalize_mimo(rxGrid, Ghat, dataPositions, noiseVar, cfg)
%% ZF and Unbiased-MMSE MIMO Equalization:
%%
%{
The equalize_mimo function recovers the transmitted layer vector on every data resource element by linear
equalization of the received antenna vector against the supplied effective-channel estimate. In the zero-forcing
mode the equalizer is the pseudo-inverse of the effective channel, which removes the inter-layer interference
completely at the cost of noise enhancement. In the MMSE mode the noise-variance term regularizes the Gram-matrix
inverse, providing robustness at low signal-to-noise ratio and under channel-estimation error; the two equalizers
converge at high signal-to-noise ratio as the regularization term vanishes. The raw MMSE output is biased: its
conditional mean shrinks the symbol amplitude by the per-layer factor given by the diagonal of the equalizer-channel
product, which degrades hard-decision slicing of amplitude-bearing constellations such as 16-QAM and above. The
function therefore applies the standard unbiased-MMSE correction by dividing each layer output by its bias factor;
the classical result that the unbiased MMSE output SINR is never below the zero-forcing SINR then holds, so the
corrected MMSE cannot perform worse than ZF. A soft-decision receiver absorbs the same bias inside its LLR noise
normalization, which is why the correction is stated explicitly only in this hard-decision chain.

Input:

    rxGrid                        Received antenna grid of size nSymbols x nSC x nRx.
    Ghat                          Effective-channel estimate of size nSC x nRx x nLayers.
    dataPositions                 Symbol and subcarrier indices of every data resource element.
    noiseVar                      Complex receiver-noise variance.
    cfg.equalizer                 Selected equalizer, zf or mmse.
    cfg.nLayers                   Number of spatial layers.

Output:

    shat                          Equalized layer symbols, one row per data resource element.
%}
%% Per-resource-element equalization:
%%

nData = size(dataPositions,1);                     % Number of data resource elements.
shat = complex(zeros(nData,cfg.nLayers));          % Preallocated equalized layer symbols.
I = eye(cfg.nLayers);                              % Identity of the layer dimension.
for p = 1:nData                                    % One data resource element per iteration.
    m = dataPositions(p,1); k = dataPositions(p,2);            % Symbol and subcarrier of this element.
    G = squeeze(Ghat(k,:,:));                      % Effective-channel estimate on this subcarrier.
    y = squeeze(rxGrid(m,k,:));                    % Received antenna vector on this resource element.
    if strcmpi(cfg.equalizer,'zf')
        Weq = pinv(G);                             % Zero-forcing pseudo-inverse, unbiased by construction.
        shat(p,:) = (Weq*y).';                     % Equalized layer vector of this element.
    else
        Weq = (G'*G + noiseVar*I) \ G';            % Regularized MMSE form, biased.
        d = real(diag(Weq*G));                     % Per-layer bias factor in (0,1].
        z = Weq*y;                                 % Biased MMSE output.
        shat(p,:) = (z ./ max(d, eps)).';          % Unbiased MMSE: removes the amplitude shrinkage so that
                                                   % hard-decision slicing of amplitude-bearing QAM is correct.
    end
end
end
