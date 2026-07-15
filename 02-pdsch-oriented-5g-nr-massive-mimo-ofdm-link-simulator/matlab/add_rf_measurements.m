
%%
%% RF Measurement Branch Add-On:
%%
%{
The add_rf_measurements script augments the existing testbench model NR_PDSCH_LinkLevel_Sim.slx with an RF measurement
branch and is run once from the simulator folder after build_nr_pdsch_simulink has created the model. The script first
loads the locked configuration and derives the waveform dimensions, then writes the sl_waveform wrapper connecting the
new block to the verified CP-OFDM modulator, unless the wrapper already exists. It adds an OFDM Waveform block that
converts the precoded antenna-domain resource grid to the time-domain CP-OFDM waveform through the verified
ofdm_modulate function. The branch is passive: it is a deterministic function of signals that already exist in the
model and consumes no random numbers, so every BER, BLER, EVM, NMSE, and capacity result stays bit-identical after the
addition. Workspace logs of the transmit waveform and the equalized symbols are added in every case, so the companion
plot_rf_measurements script can draw the power spectral density, the PAPR CCDF, and the equalized constellation with
base MATLAB only. When the corresponding toolboxes are licensed, a live Spectrum Analyzer is attached to the transmit
waveform at the compact-grid sample rate and a live Constellation Diagram is attached to the equalized symbols, with
the reference constellation taken from the simulator's own single-source definition so that the scope's reference
markers land on the true unit-power cluster centers.

Auxiliary functions:

    config
        Locked simulation configuration providing the waveform dimensions.

    qam_constellation
        Single-source constellation definition used as the scope reference.

Input:

    NR_PDSCH_LinkLevel_Sim.slx    Existing testbench model created by build_nr_pdsch_simulink.

Output:

    sl_waveform.m                 Wrapper connecting the waveform block to the verified modulator, if not present.
    Updated model                 Saved model with the OFDM Waveform block, workspace logs, and licensed scopes.
%}


%% Locked configuration and derived dimensions:
%%

addpath(genpath(pwd));                             % Add the project directory and all subdirectories to the MATLAB path.

cfg = config();                                    % Load the locked simulation configuration.

cpLen = round(cfg.nFFT/14);                        % Cyclic-prefix length of the compact numerology.

nSamp = cfg.nSymbols * (cfg.nFFT + cpLen);         % Time-domain samples per slot.

fs = cfg.nFFT * cfg.subcarrierSpacingHz;           % Sample rate of the compact grid.

fprintf('Waveform branch: %d samples/slot, Fs = %.4g MHz\n', nSamp, fs/1e6);


%% Wrapper connecting the waveform block to the verified OFDM modulator:
%%

if exist('sl_waveform.m', 'file')                  % The formatted wrapper file is preserved when present.
    fprintf('Kept existing sl_waveform.m\n');
else
    fid = fopen('sl_waveform.m', 'w');             % Wrapper written only when missing.
    fprintf(fid, '%s', sprintf([ ...
    'function txWave = sl_waveform(layerGrid, W)\n' ...
    '%% Precoded antenna-domain resource grid, centered in the FFT window, then\n' ...
    '%% the verified unitary CP-OFDM modulator (ofdm_modulate).\n' ...
    'cfg = config();\n' ...
    'off = (cfg.nFFT - cfg.nSC)/2;\n' ...
    'X = complex(zeros(cfg.nFFT, cfg.nSymbols, cfg.nTx));\n' ...
    'for m = 1:cfg.nSymbols\n' ...
    '    for k = 1:cfg.nSC\n' ...
    '        s = reshape(layerGrid(m,k,:), [], 1);\n' ...
    '        X(off+k, m, :) = W*s;\n' ...
    '    end\n' ...
    'end\n' ...
    'txWave = ofdm_modulate(X, cfg);\n' ...
    'end\n']));
    fclose(fid);
    fprintf('Wrote sl_waveform.m\n');
end


%% Open the model and add the waveform block:
%%

mdl = 'NR_PDSCH_LinkLevel_Sim';                    % Testbench model name.

load_system(mdl);                                  % Load the model without opening the editor window.

if getSimulinkBlockHandle([mdl '/OFDM Waveform']) > 0          % Skip when the branch was added before.
    fprintf('Measurement branch already present; nothing to do.\n'); return
end

add_block('simulink/User-Defined Functions/MATLAB Function', ...   % MATLAB Function block hosting the waveform call.
    [mdl '/OFDM Waveform'], 'Position', [640 430 820 510]);

rt = sfroot;                                       % Root object giving access to the block script.

ch = rt.find('-isa', 'Stateflow.EMChart', 'Path', [mdl '/OFDM Waveform']);   % Script object of the new block.

ch.Script = sprintf([ ...                          % Block script: fixed-size output, extrinsic wrapper call.
'function txWave = fcn(layerGrid, W)\n' ...
'%% ofdm_modulate on the precoded grid: time-domain CP-OFDM waveform\n' ...
'coder.extrinsic(''sl_waveform'');\n' ...
'txWave = complex(zeros(%d,%d));\n' ...
'txWave = sl_waveform(layerGrid, W);\n'], nSamp, cfg.nTx);

add_line(mdl, 'PDSCH Transmitter/1', 'OFDM Waveform/1', 'autorouting', 'on');    % Layer grid into the block.

add_line(mdl, 'Wideband SVD Precoder/1', 'OFDM Waveform/2', 'autorouting', 'on');   % Precoder into the block.


%% Workspace logs for the toolbox-free measurement plots:
%%

add_block('simulink/Sinks/To Workspace', [mdl '/Log txWaveform'], ...            % Transmit-waveform log.
    'Position', [880 430 990 462], 'VariableName', 'log_txWaveform', 'SaveFormat', 'Array');

add_line(mdl, 'OFDM Waveform/1', 'Log txWaveform/1', 'autorouting', 'on');

add_block('simulink/Sinks/To Workspace', [mdl '/Log shat'], ...                  % Equalized-symbol log.
    'Position', [1420 430 1530 462], 'VariableName', 'log_shat', 'SaveFormat', 'Array');

add_line(mdl, 'ZF-MMSE Equalizer/1', 'Log shat/1', 'autorouting', 'on');


%% Live Spectrum Analyzer on the transmit waveform, when licensed:
%%

specOk = false;                                                                  % The library path differs across releases
for cand = {'dspsnks4/Spectrum Analyzer', 'dsp/Spectrum Analyzer', ...           % candidates are tried in order.
            'spectrumAnalyzerBlockLib/Spectrum Analyzer'}
    try
        add_block(cand{1}, [mdl '/Tx Spectrum'], 'Position', [880 480 940 540]);
        specOk = true; break
    catch
    end
end
if specOk
    add_line(mdl, 'OFDM Waveform/1', 'Tx Spectrum/1', 'autorouting', 'on');
    try set_param([mdl '/Tx Spectrum'], 'SampleRateSource', 'Property'); catch, end     % Fixed sample rate;
    try set_param([mdl '/Tx Spectrum'], 'InheritSampleRate', 'off'); catch, end         % parameter names vary
    try set_param([mdl '/Tx Spectrum'], 'SampleRate', num2str(fs)); catch, end          % across releases.
    fprintf('Added live Spectrum Analyzer (DSP System Toolbox).\n');
else
    fprintf('Spectrum Analyzer block could not be added; use plot_rf_measurements after the run.\n');
end


%% Live Constellation Diagram on the equalized symbols, when licensed:
%%

add_block('simulink/Math Operations/Reshape', [mdl '/Flatten shat'], ...         % Symbol matrix flattened for the scope.
    'Position', [1420 480 1460 510], 'OutputDimensionality', '1-D array');

constOk = false;                                   % The sinks library path also differs across releases.
for cand = {'commsink2/Constellation Diagram', 'commsinks2/Constellation Diagram', ...
            'commsink3/Constellation Diagram'}
    try
        add_block(cand{1}, [mdl '/Rx Constellation'], 'Position', [1490 480 1550 540]);
        constOk = true; break
    catch
    end
end
if constOk
    add_line(mdl, 'ZF-MMSE Equalizer/1', 'Flatten shat/1', 'autorouting', 'on');
    add_line(mdl, 'Flatten shat/1', 'Rx Constellation/1', 'autorouting', 'on');
    [~, refVals] = qam_constellation(cfg.modulation);          % Reference from the single-source definition,
    refStr = mat2str(refVals.', 6);                % so the scope markers land on the true unit-power
    refSet = false;                                % cluster centers. The setting is verified by read-back
    try                                            % rather than assumed: a silent failure here leaves the
        set_param([mdl '/Rx Constellation'], ...   % scope showing its default QPSK markers, which is the
            'ReferenceConstellation', refStr);     % defect observed on the massive bench.
        refSet = strcmp(strtrim(get_param([mdl '/Rx Constellation'], ...
            'ReferenceConstellation')), strtrim(refStr));
    catch refErr
        fprintf('Reference constellation could not be set: %s\n', refErr.message);
    end
    if refSet
        fprintf('Added live Constellation Diagram; %s reference markers verified by read-back.\n', ...
            cfg.modulation);
    else
        fprintf(['Constellation Diagram added, but the %s reference markers are NOT set;\n' ...
                 'the scope shows its default QPSK markers. Run fix_massive_bench to repair.\n'], ...
            cfg.modulation);
    end
else
    try delete_block([mdl '/Flatten shat']); catch, end        % Remove the orphan reshape when no scope exists.
    fprintf('Constellation Diagram block could not be added; use plot_rf_measurements after the run.\n');
end


%% Label and save:
%%

try
    a = Simulink.Annotation(mdl, 'RF MEASUREMENTS');           % Section label above the new branch.
    try a.Position = [640 410]; catch, a.Position = [640 410 900 436]; end
    a.FontSize = 12; a.FontWeight = 'bold';
catch
end

save_system(mdl);                                  % Save the updated model.

fprintf(['\nMeasurement branch added. Run the model, then run:\n' ...
         '    plot_rf_measurements\n' ...
         'for the PSD, PAPR CCDF, and constellation figures (no toolboxes needed).\n']);
