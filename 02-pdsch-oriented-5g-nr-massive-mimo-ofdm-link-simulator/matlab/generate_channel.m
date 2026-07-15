
%%
function H = generate_channel(cfg)

%% Frequency-Domain MIMO Channel Generation:
%%
%{
The generate_channel function returns one independent frequency-domain channel realization over the active
subcarriers, quasi-static over the slot. The AWGN mode returns an identity mapping of layers to antennas with unity
gain. The flat Rayleigh mode draws one complex Gaussian matrix per frame and replicates it across all subcarriers.
The per-subcarrier Rayleigh mode draws an independent complex Gaussian matrix on every subcarrier and is a
frequency-selective variant. The Rician mode combines a deterministic line-of-sight component with a scaled Rayleigh
component according to the configured K-factor. The tapped-delay-line mode draws complex Gaussian tap gains scaled by
the configured power-delay profile, transforms them to the frequency domain through the per-tap linear phase across
the centered subcarrier grid, and normalizes the result to unit average channel power so that the total-transmit-SNR
convention holds identically for every model.

Input:

    cfg.channelModel              Selected channel model name.
    cfg.nSC                       Number of active subcarriers.
    cfg.nRx                       Number of receive antennas.
    cfg.nTx                       Number of transmit antennas.
    cfg.nFFT                      FFT size used by the tapped-delay-line phase calculation.
    cfg.ricianKDb                 Rician K-factor in decibels.
    cfg.tdlDelays                 Tapped-delay-line tap delays in samples.
    cfg.tdlPowersDb               Tapped-delay-line tap powers in decibels.

Output:

    H                             Channel realization of size nSC x nRx x nTx.
%}
model = lower(cfg.channelModel);                   % Case-insensitive model selection.

if strcmp(model,'awgn')

    %% Identity mapping of layers to antennas, unity gain, no fading:
    %%

    H = complex(zeros(cfg.nSC,cfg.nRx,cfg.nTx));   % Preallocated channel of the identity mapping.
    for i = 1:min(cfg.nRx,cfg.nTx)
        H(:,i,i) = 1;                              % Unity gain on the diagonal antenna pairs.
    end

elseif strcmp(model,'rayleigh_flat') || strcmp(model,'rayleigh')

    %% Flat Rayleigh, one draw per frame replicated over subcarriers:
    %%

    H0 = (randn(1,cfg.nRx,cfg.nTx)+1j*randn(1,cfg.nRx,cfg.nTx))/sqrt(2);   % One complex Gaussian draw.
    H = repmat(H0, cfg.nSC, 1, 1);                 % Constant over the subcarrier axis.

elseif strcmp(model,'rayleigh_iid')

    %% Frequency-selective variant, independent draw per subcarrier:
    %%

    H = (randn(cfg.nSC,cfg.nRx,cfg.nTx)+1j*randn(cfg.nSC,cfg.nRx,cfg.nTx))/sqrt(2);   % Independent per subcarrier.

elseif strcmp(model,'rician')

    %% Rician, deterministic line-of-sight plus scaled Rayleigh component:
    %%

    K = 10^(cfg.ricianKDb/10);                     % Linear K-factor.
    Hlos = ones(cfg.nSC,cfg.nRx,cfg.nTx);          % Deterministic line-of-sight component.
    Hnlos = (randn(cfg.nSC,cfg.nRx,cfg.nTx)+1j*randn(cfg.nSC,cfg.nRx,cfg.nTx))/sqrt(2);   % Scattered component.
    H = sqrt(K/(K+1))*Hlos + sqrt(1/(K+1))*Hnlos;  % K-factor combination of the two components.

elseif strcmp(model,'tdl')

    %% Tapped delay line, per-tap Rayleigh gains transformed to frequency:
    %%

    delays = cfg.tdlDelays(:);                     % Tap delays in samples.
    powers = 10.^(cfg.tdlPowersDb(:)/10);          % Linear tap powers.
    powers = powers/sum(powers);                   % Unit total tap power.
    taps = (randn(length(delays),cfg.nRx,cfg.nTx)+1j*randn(length(delays),cfg.nRx,cfg.nTx))/sqrt(2);   % Tap gains.
    for l = 1:length(delays)
        taps(l,:,:) = taps(l,:,:)*sqrt(powers(l)); % Tap gain scaled by its profile power.
    end
    kk = (0:cfg.nSC-1).' - cfg.nSC/2;              % Subcarrier index with the grid centered in the FFT.
    H = complex(zeros(cfg.nSC,cfg.nRx,cfg.nTx));   % Frequency-domain accumulation of the taps.
    for l = 1:length(delays)
        phase = exp(-1j*2*pi*kk*delays(l)/cfg.nFFT);           % Linear phase of this tap delay.
        H = H + reshape(phase,[],1,1).*reshape(taps(l,:,:),1,cfg.nRx,cfg.nTx);   % Tap contribution added.
    end
    H = H / sqrt(mean(abs(H(:)).^2));              % Unit average channel power for the SNR convention.

else
    error('Unsupported channel model');
end
end
