
%% 
function cfg = config(profile)

%% Locked Simulation Configuration:
%%
%{
The config function defines the complete locked configuration of the compact PDSCH-oriented Massive MIMO-OFDM
link-level simulator and is the single source of every simulation parameter. The reproducibility section fixes the
random seed, the total-transmit-SNR grid, and the number of Monte Carlo frames per SNR point. The numerology section
defines the compact OFDM grid of a 256-point FFT with 144 active subcarriers over one 14-symbol slot at the 30 kHz
subcarrier spacing, together with the 0.5 millisecond slot duration used by the throughput calculation. The MIMO
section sets the antenna counts, the number of spatial layers, and the precoder selection, where the default wideband
eigenbeamforming keeps the effective channel smooth in frequency so that the interpolating least-squares estimator
remains valid on frequency-selective channels. The modulation section selects the constellation from the
QPSK-to-256-QAM range and defines the CRC24A generator polynomial together with the RNTI and scrambling identity that
form the Gold-sequence initialization. The DM-RS section defines the layer-orthogonal comb structure, the channel
section selects among the AWGN, flat Rayleigh, per-subcarrier Rayleigh, Rician, and tapped-delay-line models with
their parameters, the receiver section selects the zero-forcing or MMSE equalizer, and the output section defines the
CSV and figure destinations. The final section derives the bits-per-symbol value from the selected modulation order.
This is the compact verification configuration; the processing chain, the algorithms, and the metric definitions are
identical to the full design, and the reduced grid keeps the simulation runs fast and reproducible.

Input:

    profile                       Optional profile name: compact (default) or massive (64x8, L = 4,
                                  the executed massive comparison configuration). When absent, the
                                  optional sim_profile.txt file in the folder selects the profile.

Output:

    cfg                           Complete simulation configuration structure consumed by every simulator function.
%}


%% Reproducibility and run control:
%%

cfg.randomSeed = 7;                 % Fixed seed for reproducible Monte Carlo runs.
cfg.snrDb = 0:5:25;                 % Total transmit-SNR grid in decibels.
cfg.numFrames = 40;                 % Monte Carlo frames per SNR point.


%% OFDM numerology:
%%

cfg.nFFT = 256;                     % FFT size of the compact grid.
cfg.nSC = 144;                      % Active subcarriers, centered in the FFT.
cfg.nSymbols = 14;                  % One slot of OFDM symbols.
cfg.subcarrierSpacingHz = 30e3;     % Subcarrier spacing of the baseline numerology.
cfg.slotDurationS = 0.5e-3;         % Fourteen-symbol slot duration used by the throughput calculation.


%% MIMO configuration:
%%

cfg.nTx = 4;                        % Transmit antennas.
cfg.nRx = 4;                        % Receive antennas; requires nRx >= nLayers.
cfg.nLayers = 2;                    % Spatial layers.
cfg.precoder = 'svd';               % 'svd'       = wideband eigenbeamforming (default,
                                    %               safe with the interpolating LS estimator)
                                    % 'svd_persc' = per-subcarrier SVD; ideal CSI only on
                                    %               frequency-selective channels
                                    % 'mrt'       = maximum-ratio transmission, single layer
                                    % 'identity'  = unprecoded spatial multiplexing
                                    % 'dft'       = fixed unitary baseline


%% Modulation, scrambling, and CRC:
%%

cfg.modulation = '16QAM';           % QPSK | 16QAM | 64QAM | 256QAM.
cfg.crcPoly = hex2dec('864CFB');    % CRC24A generator, TS 38.212.
cfg.crcLen = 24;                    % CRC24A parity length in bits.
cfg.nID = 1;                        % Scrambling identity entering the sequence initialization.
cfg.rnti = hex2dec('1234');         % RNTI entering the sequence initialization, TS 38.211.


%% DM-RS structure:
%%

cfg.dmrsSymbols = [4 11];           % One-based DM-RS symbol indices within the slot.
cfg.dmrsSpacing = 4;                % Comb spacing per layer across subcarriers.


%% Channel model:
%%

cfg.channelModel = 'tdl';           % 'awgn' | 'rayleigh_flat' | 'rayleigh_iid' | 'rician' | 'tdl'.
                                    % rayleigh_flat draws one realization per frame, constant over
                                    % subcarriers; rayleigh_iid draws independently per subcarrier.
cfg.ricianKDb = 8.0;                % Rician K-factor in decibels.
cfg.tdlDelays = [0 2 5 9 14];       % Tap delays in samples.
cfg.tdlPowersDb = [0 -2.2 -4.0 -6.0 -8.2];  % Tap powers in decibels, normalized in generate_channel.


%% Receiver:
%%

cfg.equalizer = 'mmse';             % 'zf' or 'mmse'.


%% Output locations:
%%

cfg.outputCsv = '../04_Simulation_Results/MATLAB/csv/matlab_results_corrected.csv';
cfg.outputFigDir = '../04_Simulation_Results/MATLAB/figures';


%% Simulation profile selection:
%%

if nargin < 1                                      % Default profile when no argument is given.
    profile = 'compact';                           % Compact verification configuration of the reference results.
    if exist(fullfile(pwd,'sim_profile.txt'),'file')           % Optional persistent profile switch, written by
        profile = strtrim(fileread('sim_profile.txt'));        % set_sim_profile, read here so the Simulink
    end                                            % wrappers follow the selected profile automatically.
end

if strcmpi(profile,'massive')                      % Massive MIMO configuration of the executed 64x8 comparison:
    cfg.nTx = 64;                                  % Sixty-four transmit antennas.
    cfg.nRx = 8;                                   % Eight receive antennas.
    cfg.nLayers = 4;                               % Four spatial layers.
    cfg.precoder = 'svd';                          % Wideband eigen-beamforming over the large array.
    cfg.channelModel = 'rayleigh_flat';            % Flat Rayleigh, matching the massive comparison run.
    cfg.snrDb = -10:5:20;                          % SNR grid of the massive comparison.
    cfg.numFrames = 60;                            % Monte Carlo frames per SNR point of that run.
    cfg.outputCsv = '../04_Simulation_Results/MATLAB/csv/matlab_results_massive.csv';   % Separate result file.
elseif ~strcmpi(profile,'compact')
    error('Unknown profile: %s (use compact or massive)', profile);
end


%% Derived modulation parameter:
%%

switch upper(cfg.modulation)
    case 'QPSK',   cfg.bitsPerSymbol = 2;
    case '16QAM',  cfg.bitsPerSymbol = 4;
    case '64QAM',  cfg.bitsPerSymbol = 6;
    case '256QAM', cfg.bitsPerSymbol = 8;
    otherwise, error('Unsupported modulation');
end
end
