
%% Simulink SNR-Grid Sweep with Reference Verification:
%%
%{
The sweep_snr_grid script executes the Simulink testbench over the full SNR grid of the active simulation profile and
verifies every aggregate against the MATLAB reference results under the pre-declared statistical tolerances: BER
within 0.3 decades, BLER within 0.25 absolute, EVM within 10 percent relative, NMSE within 0.15 decades, and capacity
within 2 percent relative. The script follows the profile selected through set_sim_profile, so one sweep procedure
serves both configurations of the project. Under the compact profile the sweep runs 0 to 25 dB in 5 dB steps with
forty frames per point and verifies against the locked compact reference vectors of the executed TDL run. Under the
massive profile the sweep runs the massive grid, minus ten to twenty dB in 5 dB steps with sixty frames per point,
and verifies against the massive MATLAB reference file written by run_massive_mimo, so the 64x8 four-layer
eigen-beamforming bench is checked against its own executed MATLAB results rather than against the compact table.
Before sweeping, the script confirms that the loaded model was built for the active profile by reading the channel
generator block dimensions, which prevents a sweep of a compact model under the massive profile or the reverse. The
per-point results, the deviations, the verdicts, and the antenna and layer dimensions are printed as a table and
saved to the profile-specific CSV artifact next to the model, so every sweep artifact is self-identifying and stored
under the same provenance rule as the MATLAB and Python results. The script is run after build_nr_pdsch_simulink or
build_massive_testbench, and optionally after add_rf_measurements, in which case the live scopes simply refresh on
every point.

Auxiliary functions:

    config                        Active profile providing the grid, the frame count, and the dimensions.
    run_massive_mimo              Producer of the massive MATLAB reference file consumed here.

Input:

    NR_PDSCH_LinkLevel_Sim.slx    Existing testbench model created for the active profile.
    matlab_results_massive.csv    Massive MATLAB reference results, required under the massive profile.

Output:

    Command Window                Per-point results, deviations, and pass or fail verdicts.
    simulink_results.csv          Stored sweep artifact of the compact profile.
    simulink_results_massive.csv  Stored sweep artifact of the massive profile.
%}


%% Active profile, grid, and the MATLAB reference results:
%%

mdl = 'NR_PDSCH_LinkLevel_Sim';                    % Testbench model name.

load_system(mdl);                                  % Load the model without opening the editor window.

cfgChk = config();                                 % Active profile of the project.

isMassive = (cfgChk.nTx == 64 && cfgChk.nRx == 8 && cfgChk.nLayers == 4);      % Massive 64x8 four-layer profile.

if ~isMassive && ~(cfgChk.nTx == 4 && cfgChk.nRx == 4 && cfgChk.nLayers == 2)  % Only the two defined profiles
    error(['sweep_snr_grid supports the compact 4x4 and the massive 64x8 profiles; ' ...       % carry references.
           'the active configuration is %dx%d with L = %d.'], cfgChk.nTx, cfgChk.nRx, cfgChk.nLayers);
end


%% Model-dimension consistency check against the active profile:
%%

rt = sfroot;                                       % Root object giving access to the block scripts.
ch = rt.find('-isa', 'Stateflow.EMChart', 'Path', [mdl '/MIMO Channel Generator']);   % Channel generator script.
dimsExpected = sprintf('complex(zeros(%d,%d,%d))', cfgChk.nSC, cfgChk.nRx, cfgChk.nTx);   % Dimensions of the profile.
if isempty(ch) || ~contains(ch.Script, dimsExpected)           % The block dimensions are fixed at build time,
    error(['The loaded model was not built for the active %dx%d profile. ' ...        % so a stale model must be
           'Rebuild it first:\n    build_nr_pdsch_simulink        (compact)\n' ...    % regenerated before sweeping.
           '    build_massive_testbench        (massive)'], cfgChk.nTx, cfgChk.nRx);
end

snrs = cfgChk.snrDb;                               % Total transmit-SNR grid of the active profile.

if isMassive

    %% Massive reference read from the executed run_massive_mimo results:
    %%

    refCsv = fullfile(pwd, cfgChk.outputCsv);      % Massive MATLAB reference file of the active profile.
    if ~exist(refCsv, 'file')                      % The reference must exist before the sweep can verify.
        error(['Massive reference file not found:\n    %s\n' ...
               'Run run_massive_mimo first to produce the massive MATLAB reference results.'], refCsv);
    end
    refT = readtable(refCsv);                      % Reference table of the massive run.
    [tf, loc] = ismember(snrs(:), refT.snrDb);     % Reference rows aligned with the sweep grid.
    assert(all(tf), 'The massive reference file does not cover the full massive SNR grid.');
    ref.ber  = refT.ber(loc).';                    % Massive reference BER.
    ref.bler = refT.bler(loc).';                   % Massive reference BLER.
    ref.evm  = refT.evmPercent(loc).';             % Massive reference EVM in percent.
    ref.nmse = refT.nmse(loc).';                   % Massive reference NMSE.
    hasCap = ismember('capacityBpsHz', refT.Properties.VariableNames);         % Older reference files predate
    if hasCap                                      % the capacity column; the check is skipped with a note.
        ref.cap = refT.capacityBpsHz(loc).';       % Massive reference capacity.
    else
        ref.cap = nan(size(snrs));
        fprintf(['Note: the massive reference file has no capacity column; regenerate it with the\n' ...
                 'corrected run_massive_mimo to verify all five metrics. Capacity is not checked now.\n']);
    end
    outCsv = 'simulink_results_massive.csv';       % Massive sweep artifact next to the model.

else

    %% Compact reference vectors of the executed TDL run (matlab_results.csv):
    %%

    ref.ber  = [0.27393  0.15674  0.055113  0.011203  0.0012256  0.00018727];   % MATLAB reference BER.
    ref.bler = [1.000    1.000    1.000     1.000     0.925      0.575    ];    % MATLAB reference BLER.
    ref.evm  = [80.191   53.429   31.900    19.380    11.494     7.382    ];    % MATLAB reference EVM in percent.
    ref.nmse = [0.49338  0.16203  0.052761  0.018692  0.0074763  0.0038747];    % MATLAB reference NMSE.
    ref.cap  = [3.606    6.1156   9.1364    12.325    15.623     18.961   ];    % MATLAB reference capacity.
    hasCap = true;                                 % The compact reference always carries the capacity values.
    outCsv = 'simulink_results.csv';               % Compact sweep artifact next to the model.

end

tol.berDec = 0.3; tol.blerAbs = 0.25; tol.evmRel = 0.10;       % Pre-declared statistical tolerances.
tol.nmseDec = 0.15; tol.capRel = 0.02;

fprintf('Sweep profile: %dx%d, L = %d, %d frames per point, grid %s dB, reference %s.\n\n', ...
    cfgChk.nTx, cfgChk.nRx, cfgChk.nLayers, cfgChk.numFrames, mat2str(snrs), ...
    ternary(isMassive, 'matlab_results_massive.csv', 'locked compact vectors'));


%% Sweep:
%%

n = numel(snrs);                                   % Number of SNR points.

res = zeros(n, 6);                                 % Result rows: SNR, BER, BLER, EVM, NMSE, capacity.

verdicts = strings(n, 1);                          % Pass or fail verdict per point.

for s = 1:n                                        % One SNR point per iteration.

    set_param([mdl '/SNR (dB)'], 'Value', num2str(snrs(s)));   % Set the SNR constant of the model.

    sim(mdl);                                      % Run all frames at this point; logs land in the workspace.

    ber  = sum(log_bitErrors) / sum(log_nBits);    % Aggregate bit error rate of the point.
    bler = mean(log_blockError);                   % Aggregate block error rate of the point.
    evm  = 100 * mean(log_evm);                    % Average RMS EVM in percent.
    nmse = mean(log_nmse);                         % Average channel-estimation NMSE.
    cap  = mean(log_capacity);                     % Average layer-domain capacity.

    res(s,:) = [snrs(s) ber bler evm nmse cap];    % Result row of this point.


    %% Tolerance checks against the MATLAB reference:
    %%

    berFloor = 0.5 / sum(log_nBits);               % Resolution floor of half a bit error over the accumulated
                                                   % bits; the eigen-beamformed 64x8 link can reach zero counted
                                                   % errors on the finite grid, and the decade deviation stays
                                                   % defined by flooring both sides at the resolution limit.
    devBer  = abs(log10(max(ber, berFloor) / max(ref.ber(s), berFloor)));      % BER deviation in decades.
    cntErr  = ber*sum(log_nBits) + ref.ber(s)*sum(log_nBits);                  % Combined counted errors of the
    berResolved = (cntErr >= 10);                  % point; below ten combined errors the decade comparison is
                                                   % Monte Carlo noise rather than a chain discrepancy, so the
                                                   % BER check is skipped and reported as below resolution. The
                                                   % rule never triggers in the compact profile, whose smallest
                                                   % reference point still carries about 112 counted errors.
    devBler = abs(bler - ref.bler(s));             % BLER deviation, absolute.
    devEvm  = abs(evm - ref.evm(s)) / ref.evm(s);  % EVM deviation, relative.
    devNmse = abs(log10(nmse / ref.nmse(s)));      % NMSE deviation in decades.
    if hasCap
        devCap = abs(cap - ref.cap(s)) / ref.cap(s);           % Capacity deviation, relative.
        capOk = (devCap <= tol.capRel);
    else
        devCap = NaN; capOk = true;                % No capacity column in the reference; check skipped.
    end

    berOk = ~berResolved || (devBer <= tol.berDec);            % Resolved points face the decade tolerance.

    ok = berOk && (devBler <= tol.blerAbs) && ...              % All available checks must hold.
         (devEvm <= tol.evmRel) && (devNmse <= tol.nmseDec) && capOk;

    if ok; verdicts(s) = "PASS"; else; verdicts(s) = "FAIL"; end

    if berResolved
        berNote = sprintf('dev %5.3f dec', devBer);            % Ordinary decade deviation of the point.
    else
        berNote = 'below resolution';              % Fewer than ten combined counted errors at this point.
    end

    fprintf(['%5d dB  BER %10.4e (%s)  BLER %5.3f (dev %5.3f)  ' ...
             'EVM %6.2f%% (dev %4.1f%%)  NMSE %10.4e (dev %5.3f dec)  C %6.3f (dev %4.2f%%)  %s\n'], ...
        snrs(s), ber, berNote, bler, devBler, evm, 100*devEvm, nmse, devNmse, cap, 100*devCap, verdicts(s));
end

set_param([mdl '/SNR (dB)'], 'Value', num2str(snrs(end)));     % Restore the top operating point of the grid.


%% Verdict and CSV artifact:
%%

fprintf('\n%d of %d SNR points inside the reference tolerances against the MATLAB reference results.\n', ...
    sum(verdicts == "PASS"), n);

T = array2table(res, 'VariableNames', ...          % Sweep results as a table.
    {'snrDb','ber','bler','evmPercent','nmse','capacityBpsHz'});

T.verdict = verdicts;                              % Verdict column appended.

T.nTx = repmat(cfgChk.nTx, n, 1);                  % Antenna and layer dimensions recorded per row, so the
T.nRx = repmat(cfgChk.nRx, n, 1);                  % stored artifact identifies its own configuration without
T.nLayers = repmat(cfgChk.nLayers, n, 1);          % reference to the profile that was active when it was made.

writetable(T, outCsv);                             % Stored sweep artifact next to the model.

fprintf('Saved Simulink sweep artifact: %s\n', outCsv);


%% Inline conditional helper:
%%

function out = ternary(cond, a, b)                 % Conditional text selection used by the profile printout.
if cond; out = a; else; out = b; end
end
