
%% *** PDSCH-Oriented Massive MIMO-OFDM Monte Carlo Simulation ***:
%% This is the main code for the simulation: 
%{
The main script executes the complete PDSCH-oriented Massive MIMO-OFDM link-level simulation over the configured
total-transmit-SNR range. It initializes the MATLAB environment, loads the locked simulation configuration, adds the
complete project directory to the MATLAB path, and seeds the random-number generator so that every Monte Carlo run can
be repeated with the same channel, noise, payload, and DM-RS realizations.

Before starting the simulation, the script verifies that the receiver has at least as many observations as the number
of transmitted spatial layers. It then executes the project verification gates covering QAM constellation
normalization, the noiseless modulation-demodulation round trip, the OFDM modulation-demodulation round trip, and the
CRC24A accept and reject operations. The simulation is stopped immediately when any verification gate fails.

For each configured SNR point, the script processes the required number of independent Monte Carlo frames. A frame is
constructed by generating a transport block, attaching CRC24A, scrambling the transmitted bits, performing QAM mapping,
mapping the symbols to spatial layers, and inserting layer-specific DM-RS symbols into the resource grid. An independent
frequency-domain MIMO channel is generated for every frame, and a wideband eigen-beamforming precoder is calculated from
the channel realization.

The precoded layer grid is passed through the MIMO channel and complex additive receiver noise is added according to the
configured total-transmit-SNR definition. The effective channel is estimated from the received DM-RS resource elements
using least-squares estimation, time averaging, and frequency interpolation. The data resource elements are then recovered
using the configured zero-forcing or MMSE MIMO equalizer.

The receiver calculates the detected-bit errors, CRC block decision, RMS error vector magnitude, effective-channel
estimation NMSE, successfully delivered payload, and layer-domain MIMO capacity reference. The frame-level values are
accumulated over all frames to obtain BER, BLER, EVM, NMSE, throughput, spectral efficiency, and capacity at each SNR point.

After completing the SNR sweep, the per-SNR result structures are converted into a MATLAB table. The table is written to
the configured CSV file, and the exact simulation configuration is stored in a text log for result traceability. Finally,
the script creates and saves the seven result figures for BER, BLER, EVM, channel-estimation NMSE, throughput, spectral
efficiency, and MIMO capacity.

Auxiliary functions:

    config
        Defines the complete simulation configuration, including the antenna dimensions, modulation, SNR grid, channel
        model, equalizer, number of Monte Carlo frames, output files, and reproducibility seed.

    run_verification_gates
        Verifies constellation normalization, modulation recovery, OFDM recovery, and CRC24A accept/reject operation
        before the main simulation is allowed to run.

    build_frame
        Generates the payload, attaches CRC24A, scrambles the bit sequence, maps the bits to QAM symbols, performs layer
        mapping, inserts DM-RS symbols, and returns the complete transmit resource grid.

    generate_channel
        Generates one independent frequency-domain MIMO channel realization over the configured active subcarriers.

    compute_precoder
        Calculates the configured wideband precoding matrix, using eigen-beamforming or the selected precoder method.

    apply_mimo_channel
        Applies spatial precoding, the frequency-domain MIMO channel, and additive complex receiver noise.

    estimate_effective_channel_ls
        Estimates the effective precoded channel from the received DM-RS symbols using least-squares estimation.

    equalize_mimo
        Recovers the transmitted layer symbols using zero-forcing or MMSE MIMO equalization.

    compute_frame_metrics
        Performs receiver-bit recovery and calculates the frame-level BER contribution, block decision, EVM, NMSE,
        successful payload, and MIMO capacity.

    write_config_log
        Writes the complete simulation configuration beside the CSV file for reproducibility and result provenance.

Input:

    cfg.randomSeed                Random-number-generator seed used for reproducible Monte Carlo runs.
    cfg.snrDb                     Vector containing the total transmit-SNR points in decibels.
    cfg.numFrames                 Number of independent Monte Carlo frames processed at each SNR point.
    cfg.nTx                       Number of transmit antennas.
    cfg.nRx                       Number of receive antennas.
    cfg.nLayers                   Number of simultaneously transmitted spatial layers.
    cfg.nSC                       Number of occupied OFDM subcarriers.
    cfg.subcarrierSpacingHz       OFDM subcarrier spacing in hertz.
    cfg.slotDurationS             Duration of one simulated slot in seconds.
    cfg.modulation                Selected QAM modulation scheme.
    cfg.channelModel              Selected frequency-domain MIMO channel model.
    cfg.equalizer                 Selected zero-forcing or MMSE equalizer.
    cfg.outputCsv                 Relative path of the output result CSV file.
    cfg.outputFigDir              Relative path of the output figure directory.

Output:

    results                       Structure array containing the aggregated result at every SNR point.
    T                             MATLAB table containing all simulation metrics and configuration dimensions.
    CSV result file               Stored BER, BLER, EVM, NMSE, throughput, spectral efficiency, and capacity results.
    Configuration log             Text file containing the exact simulation configuration.
    PNG result figures            Seven generated performance figures stored in the configured output directory.
%}


%% Initialization:
%%

clear; 
clc; 
close all;

addpath(genpath(pwd));                             % Add the project directory and all subdirectories to the MATLAB path.

cfg = config();                                    % Load the locked simulation configuration structure.

rng(cfg.randomSeed);                               % Seed the random generator for a reproducible Monte Carlo run.


%% Parameter validation:
%%

if cfg.nRx < cfg.nLayers                           % Confirm that enough receiver observations exist for layer recovery.
    error(['ZF/MMSE equalization requires ' ...    % Stop before simulation when the MIMO system is underdetermined.
           'nRx >= nLayers']);
end


%% Verification gates:
%%

run_verification_gates(cfg);                       % Execute all mandatory verification tests and abort if any gate fails.


%% Monte Carlo simulation over the SNR grid:
%%

results = [];                                      % Initialize the structure array used to store one result row per SNR point.

for isnr = 1:length(cfg.snrDb)                     % Process every configured total-transmit-SNR point.

    snrDb = cfg.snrDb(isnr);                       % Select the total transmit SNR used for the current simulation point.

    bitErrors = 0;                                 % Initialize the accumulated number of detected-bit errors.
    nBits = 0;                                     % Initialize the accumulated number of evaluated transmitted bits.
    blockErrors = 0;                               % Initialize the number of CRC-failed transport blocks.

    evmList = zeros(cfg.numFrames,1);              % Preallocate the frame-level RMS EVM result vector.
    nmseList = zeros(cfg.numFrames,1);             % Preallocate the frame-level channel-estimation NMSE vector.
    capacityList = zeros(cfg.numFrames,1);         % Preallocate the frame-level MIMO capacity reference vector.

    payloadSuccess = 0;                            % Initialize the number of payload bits delivered in CRC-passed blocks.
    payloadTotal = 0;                              % Initialize the total generated payload-bit counter.


    %% Frame processing at the current SNR point:
    %%

    for iframe = 1:cfg.numFrames                   % Generate and process all independent frames at the current SNR.


        %% Transmitter frame generation:
        %%

        frame = build_frame(cfg);                  % Generate payload, CRC, scrambling, QAM, layers, DM-RS, and resource grid.


        %% Frequency-domain MIMO channel generation:
        %%

        H = generate_channel(cfg);                 % Generate H(k,nRx,nTx) over all configured active subcarriers.


        %% Wideband precoder calculation:
        %%

        W = compute_precoder(cfg,H);               % Calculate the configured wideband MIMO beamforming matrix.


        %% MIMO channel and receiver-noise application:
        %%

        [rxGrid,noiseVar] = apply_mimo_channel( ...% Apply y(k) = H(k)*W*s(k) + n(k) to the transmitted layer grid.
            frame.layerGrid,H,W,snrDb);            % Return the received grid and complex receiver-noise variance.


        %% DM-RS-based effective-channel estimation:
        %%

        Ghat = estimate_effective_channel_ls( ...  % Estimate the effective channel G(k) = H(k)*W from received DM-RS symbols.
            rxGrid,frame,cfg);                     % Apply LS estimation, pilot averaging, and frequency interpolation.


        %% MIMO data equalization:
        %%

        shat = equalize_mimo( ...                  % Recover the transmitted layer symbols from the received data resources.
            rxGrid,Ghat,frame.dataPositions, ...   % Supply the received grid, channel estimate, and data-resource positions.
            noiseVar,cfg);                         % Apply the configured zero-forcing or MMSE equalization matrix.


        %% Frame-level metric calculation:
        %%

        met = compute_frame_metrics( ...           % Demap the symbols, recover the bits, check CRC, and calculate metrics.
            shat,frame,Ghat,H,W,snrDb,cfg);        % Use the estimated and true effective channels for metric evaluation.


        %% Frame-level result accumulation:
        %%

        bitErrors = bitErrors + met.bitErrors;     % Add the current frame's detected-bit errors to the SNR accumulator.

        nBits = nBits + met.nBits;                 % Add the number of evaluated bits from the current frame.

        blockErrors = blockErrors + ...            % Add one block error when the recovered CRC decision fails.
            met.blockError;

        evmList(iframe) = met.evm;                 % Store the normalized RMS EVM measured for the current frame.

        nmseList(iframe) = met.nmse;               % Store the effective-channel estimation NMSE for the current frame.

        capacityList(iframe) = ...                 % Store the true layer-domain MIMO capacity reference.
            met.capacityBpsHz;

        payloadTotal = payloadTotal + ...          % Count all generated payload bits independently of CRC success.
            met.payloadBits;

        if met.blockError == 0                     % Accept payload contribution only when the transport block passes CRC.
            payloadSuccess = payloadSuccess + ...  % Accumulate successfully delivered information bits.
                met.payloadBits;
        end

    end


    %% Aggregate metrics at the current SNR point:
    %%

    row.snrDb = snrDb;                             % Store the current total transmit-SNR value.

    row.ber = bitErrors / max(1,nBits);            % Calculate BER from all evaluated bits at the current SNR.

    row.bler = blockErrors / cfg.numFrames;        % Calculate BLER from the fraction of CRC-failed transport blocks.

    row.evmPercent = 100*mean(evmList);            % Convert the average normalized RMS EVM to a percentage.

    row.nmse = mean(nmseList);                     % Calculate the average effective-channel estimation NMSE.

    row.throughputBitsPerFrame = ...               % Calculate successfully delivered payload bits per simulated frame.
        payloadSuccess / cfg.numFrames;

    row.throughputMbps = ...                       % Convert successfully delivered payload per frame to Mbit/s.
        (payloadSuccess / cfg.numFrames) / ...
        cfg.slotDurationS / 1e6;

    row.spectralEffBpsHz = ...                     % Divide successful throughput by the occupied OFDM bandwidth.
        row.throughputMbps*1e6 / ...
        (cfg.nSC*cfg.subcarrierSpacingHz);

    row.capacityBpsHz = mean(capacityList);        % Average the true layer-domain MIMO capacity over all frames.

    row.numFrames = cfg.numFrames;                 % Record the number of simulated frames for result traceability.

    row.nTx = cfg.nTx;                             % Record the configured number of transmit antennas.

    row.nRx = cfg.nRx;                             % Record the configured number of receive antennas.

    row.nLayers = cfg.nLayers;                     % Record the configured number of spatial transmission layers.

    results = [results;row]; %#ok<AGROW>           % Append the complete result row for the current SNR point.

end


%% Result-table generation:
%%

T = struct2table(results);                         % Convert the per-SNR result structure into a MATLAB table.


%% CSV result and configuration-log storage:
%%

outCsv = fullfile(pwd,cfg.outputCsv);              % Construct the absolute path of the configured CSV result file.

[folder,~,~] = fileparts(outCsv);                  % Extract the parent directory required for CSV storage.

if ~exist(folder,'dir')                            % Check whether the configured result directory already exists.
    mkdir(folder);                                 % Create the result directory when it is not present.
end

writetable(T,outCsv);                              % Write the complete simulation result table to the CSV file.

write_config_log(cfg,outCsv);                      % Archive the exact simulation configuration beside the result file.

disp(T);                                           % Display the final result table in the Command Window.

fprintf('Saved MATLAB CSV: %s\n',outCsv);          % Print the absolute CSV output location.


%% Figure-output directory preparation:
%%

figDir = fullfile(pwd,cfg.outputFigDir);           % Construct the absolute directory used for the result figures.

if ~exist(figDir,'dir')                            % Check whether the configured figure directory exists.
    mkdir(figDir);                                 % Create the figure directory when required.
end


%% Shared figure annotation:
%%

cfgStr = sprintf( ...                              % Build the common configuration string shown in every figure title.
    '%s, %dx%d, L = %d, %s, %s', ...               % Format modulation, antenna dimensions, layers, channel, and equalizer.
    upper(cfg.modulation), ...                     % Convert the modulation name to uppercase for display.
    cfg.nTx, ...                                   % Insert the configured number of transmit antennas.
    cfg.nRx, ...                                   % Insert the configured number of receive antennas.
    cfg.nLayers, ...                               % Insert the configured number of spatial layers.
    upper(cfg.channelModel), ...                   % Convert the channel-model name to uppercase.
    upper(cfg.equalizer));                         % Convert the equalizer name to uppercase.


%% BER plotting:
%%

figure(1);                                        

yBer = T.ber;                                      % Copy the simulated BER values for logarithmic plotting.

yBer(yBer == 0) = NaN;                             % Hide zero-error points because zero cannot be shown on a log axis.

semilogy(T.snrDb,yBer,'-o','LineWidth',1.2);       % Plot BER versus total transmit SNR using a logarithmic vertical axis.

grid on;                                           % Enable the major plot grid.

xlabel('Total transmit SNR (dB)');                 % Label the horizontal SNR axis.

ylabel('BER');                                     % Label the vertical bit-error-rate axis.

title({'Bit Error Rate vs SNR';cfgStr});           % Add the metric title and complete run configuration.

legend('Simulated BER', ...                        % Identify the simulated BER curve.
    'Location','southwest');                       % Position the legend in the lower-left region.

hold off;                                          % Release the current axes hold state.

saveas(figure(1), ...                              % Save the BER figure as a PNG image.
    fullfile(figDir,'ber_vs_snr.png'));


%% BLER plotting:
%%

figure(2);                                        

yBler = T.bler;                                    % Copy the simulated BLER values for logarithmic plotting.

yBler(yBler == 0) = NaN;                           % Hide zero-error points because zero cannot be plotted logarithmically.

semilogy(T.snrDb,yBler,'-o','LineWidth',1.2);      % Plot BLER versus total transmit SNR.

grid on;                                           % Enable the major plot grid.

xlabel('Total transmit SNR (dB)');                 % Label the horizontal SNR axis.

ylabel('BLER');                                    % Label the vertical block-error-rate axis.

title({ ...                                        % Add the BLER title and complete simulation configuration.
    'Block Error Rate vs SNR (uncoded transport block)'; ...
    cfgStr});

legend('Simulated BLER', ...                       % Identify the simulated BLER curve.
    'Location','southwest');                       % Position the legend in the lower-left region.

hold off;                                          % Release the current axes hold state.

saveas(figure(2), ...                              % Save the BLER figure as a PNG image.
    fullfile(figDir,'bler_vs_snr.png'));


%% EVM plotting:
%%

figure(3);                                        

plot(T.snrDb,T.evmPercent,'-o','LineWidth',1.2);   % Plot RMS EVM percentage versus total transmit SNR.

grid on;                                           % Enable the major plot grid.

xlabel('Total transmit SNR (dB)');                 % Label the horizontal SNR axis.

ylabel('EVM (%)');                                 % Label the vertical EVM-percentage axis.

title({'Error Vector Magnitude vs SNR';cfgStr});   % Add the EVM title and complete simulation configuration.

legend('RMS EVM', ...                              % Identify the simulated RMS EVM curve.
    'Location','northeast');                       % Position the legend in the upper-right region.

hold off;                                          % Release the current axes hold state.

saveas(figure(3), ...                              % Save the EVM figure as a PNG image.
    fullfile(figDir,'evm_vs_snr.png'));


%% Channel-estimation NMSE plotting:
%%

figure(4);                                         

yNmse = T.nmse;                                    % Copy the channel-estimation NMSE result values.

yNmse(yNmse == 0) = NaN;                           % Hide exact-zero values on the logarithmic vertical axis.

semilogy(T.snrDb,yNmse,'-o','LineWidth',1.2);      % Plot channel-estimation NMSE versus total transmit SNR.

grid on;                                           % Enable the major plot grid.

xlabel('Total transmit SNR (dB)');                 % Label the horizontal SNR axis.

ylabel('NMSE');                                    % Label the vertical normalized mean-square-error axis.

title({ ...                                        % Add the NMSE title and complete simulation configuration.
    'Channel-Estimation NMSE vs SNR (LS on DM-RS)'; ...
    cfgStr});

legend('LS estimation NMSE', ...                   % Identify the DM-RS least-squares estimation curve.
    'Location','southwest');                       % Position the legend in the lower-left region.

hold off;                                          % Release the current axes hold state.

saveas(figure(4), ...                              % Save the NMSE figure as a PNG image.
    fullfile(figDir,'nmse_vs_snr.png'));


%% Throughput plotting:
%%

figure(5);                                       
plot(T.snrDb,T.throughputMbps, ...                 % Plot successful payload throughput versus total transmit SNR.
    '-o','LineWidth',1.2);

grid on;                                           % Enable the major plot grid.

xlabel('Total transmit SNR (dB)');                 % Label the horizontal SNR axis.

ylabel('Throughput (Mbit/s)');                     % Label the vertical throughput axis.

title({ ...                                        % Add the throughput title and complete simulation configuration.
    'Throughput vs SNR (uncoded transport block)'; ...
    cfgStr});

legend( ...                                        % Identify the CRC-passed payload-throughput curve.
    'Throughput of CRC-passed blocks', ...
    'Location','northwest');

hold off;                                          % Release the current axes hold state.

saveas(figure(5), ...                              % Save the throughput figure as a PNG image.
    fullfile(figDir,'throughput_vs_snr.png'));


%% Spectral-efficiency plotting:
%%

figure(6);                                         

plot(T.snrDb,T.spectralEffBpsHz, ...               % Plot delivered spectral efficiency versus total transmit SNR.
    '-o','LineWidth',1.2);

grid on;                                           % Enable the major plot grid.

xlabel('Total transmit SNR (dB)');                 % Label the horizontal SNR axis.

ylabel('Spectral efficiency (bit/s/Hz)');          % Label the vertical delivered spectral-efficiency axis.

title({'Spectral Efficiency vs SNR';cfgStr});      % Add the metric title and complete simulation configuration.

legend('Spectral efficiency', ...                  % Identify the delivered spectral-efficiency curve.
    'Location','northwest');                       % Position the legend in the upper-left region.

hold off;                                          % Release the current axes hold state.

saveas(figure(6), ...                              % Save the spectral-efficiency figure as a PNG image.
    fullfile(figDir,'spectraleff_vs_snr.png'));


%% MIMO-capacity plotting:
%%

figure(7);                                         

plot(T.snrDb,T.capacityBpsHz, ...                  % Plot the layer-domain capacity reference versus total transmit SNR.
    '-o','LineWidth',1.2);

grid on;                                           % Enable the major plot grid.

xlabel('Total transmit SNR (dB)');                 % Label the horizontal SNR axis.

ylabel('Capacity (bit/s/Hz)');                     % Label the vertical layer-domain capacity axis.

title({'MIMO Capacity vs SNR';cfgStr});            % Add the capacity title and complete simulation configuration.

legend('Layer-domain capacity', ...                % Identify the calculated MIMO-capacity reference curve.
    'Location','northwest');                       % Position the legend in the upper-left region.

hold off;                                          % Release the current axes hold state.

saveas(figure(7), ...                              % Save the capacity figure as a PNG image.
    fullfile(figDir,'capacity_vs_snr.png'));


%% Simulation completion:
%%

fprintf('Saved figures to: %s\n',figDir);          
