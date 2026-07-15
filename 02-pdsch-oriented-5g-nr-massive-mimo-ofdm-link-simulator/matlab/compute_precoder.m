
%%
function W = compute_precoder(cfg, H)
%% MIMO Precoder Calculation:
%%
%{
The compute_precoder function returns the digital precoding matrix for the configured scheme. In the default wideband
mode the function accumulates the channel covariance over all active subcarriers, symmetrizes it numerically,
performs the eigendecomposition, sorts the eigenvectors by descending eigenvalue, and returns the dominant
eigenvectors as the unit-norm precoder columns; one matrix is used for all subcarriers, so the effective channel
remains as smooth in frequency as the physical channel itself, which is the condition required by the interpolating
least-squares DM-RS estimator on frequency-selective channels. On a flat channel this wideband solution coincides
with the per-subcarrier singular value decomposition. The per-subcarrier mode computes the singular value
decomposition of the channel matrix on every subcarrier and returns the dominant right singular vectors per
subcarrier; this maximizes the beamforming gain but carries an arbitrary phase per subcarrier, so it must only be
used together with ideal channel state information on frequency-selective channels. The maximum-ratio mode returns
the single dominant wideband eigenvector for one-layer transmission, the identity mode maps layers directly to
antennas for unprecoded spatial multiplexing, and the DFT mode returns fixed unitary DFT columns as an additional
baseline.

Input:

    cfg.precoder                  Selected precoder scheme name.
    cfg.nTx                       Number of transmit antennas.
    cfg.nSC                       Number of active subcarriers.
    cfg.nLayers                   Number of spatial layers.
    H                             Channel realization of size nSC x nRx x nTx.

Output:

    W                             Precoder, wideband nTx x nLayers or per-subcarrier nSC x nTx x nLayers.
%}
switch lower(cfg.precoder)

    case 'svd'

        %% Wideband eigen-beamforming from the average channel covariance:
        %%

        R = zeros(cfg.nTx);                        % Accumulated channel covariance.
        for k = 1:cfg.nSC                          % One subcarrier per iteration.
            Hk = reshape(H(k,:,:), size(H,2), cfg.nTx);        % Channel matrix on this subcarrier.
            R = R + (Hk'*Hk);                      % Covariance contribution of this subcarrier.
        end
        R = R / cfg.nSC;                           % Average covariance over the grid.
        [V,D] = eig((R+R')/2);                     % Hermitian symmetry enforced numerically before decomposition.
        [~,order] = sort(real(diag(D)),'descend'); % Eigenvectors sorted by descending eigenvalue.
        V = V(:,order);
        W = V(:,1:cfg.nLayers);                    % Dominant eigenvectors, unit-norm columns.

    case 'svd_persc'

        %% Per-subcarrier SVD, ideal-CSI use only on frequency-selective channels:
        %%

        W = complex(zeros(cfg.nSC, cfg.nTx, cfg.nLayers));     % One precoder per subcarrier.
        for k = 1:cfg.nSC
            [~,~,V] = svd(reshape(H(k,:,:), size(H,2), cfg.nTx));   % Right singular vectors of this subcarrier.
            W(k,:,:) = V(:,1:cfg.nLayers);         % Dominant directions of this subcarrier.
        end

    case 'mrt'

        %% Wideband maximum-ratio transmission, single layer:
        %%

        assert(cfg.nLayers == 1, 'MRT is a single-layer precoder');
        R = zeros(cfg.nTx);                        % Accumulated channel covariance.
        for k = 1:cfg.nSC
            Hk = reshape(H(k,:,:), size(H,2), cfg.nTx);
            R = R + (Hk'*Hk);
        end
        [V,D] = eig((R+R')/2);                     % Eigendecomposition of the symmetrized covariance.
        [~,order] = sort(real(diag(D)),'descend');
        W = V(:,order(1));                         % Single dominant eigenvector.

    case 'identity'

        %% Unprecoded spatial multiplexing, layers map directly to antennas:
        %%

        W = eye(cfg.nTx);                          % With eigen-beamforming on a flat channel the equalizers coincide,
        W = W(:, 1:cfg.nLayers);                   % so equalizer comparisons require this unprecoded configuration.

    case 'dft'

        %% Fixed unitary DFT-column baseline:
        %%

        W = dft_precoder(cfg.nTx, cfg.nLayers);    % Fixed orthonormal columns of the DFT matrix.

    otherwise
        error('Unsupported precoder');
end
end
