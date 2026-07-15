%%
%%
% Massive Test Bench In-Place Repair:
%%
%{
The fix_massive_bench script repairs the two defects observed on the executed 64x8 massive test bench without
rebuilding the model, so every annotation and layout of the existing bench is preserved. The first repair sets the
reference constellation of the Rx Constellation scope to the unit-power points of the configured modulation, taken
from the simulator's single-source constellation definition, and verifies the setting by reading the property back;
the executed massive bench showed the scope's default QPSK markers because the original setting failed silently
inside an empty catch block. The second repair updates the on-model documentation paragraph that still describes the
old compact-only sweep, which refused to run under the massive profile; the corrected sweep_snr_grid follows the
active profile and verifies the massive bench against the massive MATLAB reference file, and the annotation must say
so. The script prints one verified confirmation line per repair, saves the model, and changes nothing else, so the
BER, BLER, EVM, NMSE, and capacity results of the bench are untouched.

Auxiliary functions:

    config                        Active profile providing the modulation of the reference markers.
    qam_constellation             Single-source constellation definition used as the scope reference.

Input:

    NR_PDSCH_LinkLevel_Sim.slx    Existing test bench model with the monitoring branch attached.

Output:

    Command Window                One verified confirmation line per repair.
    Updated model                 Saved model with the correct reference markers and current documentation.
%}


%% Model and configuration:
%%

mdl = 'NR_PDSCH_LinkLevel_Sim';                    % Testbench model name.

load_system(mdl);                                  % Load the model without opening the editor window.

cfg = config();                                    % Active profile providing the modulation order.


%% Repair one, verified reference constellation of the Rx Constellation scope:
%%

if getSimulinkBlockHandle([mdl '/Rx Constellation']) > 0       % The scope exists only when the monitoring
                                                               % branch was attached with a licensed toolbox.
    [~, refVals] = qam_constellation(cfg.modulation);          % Unit-power reference points of the configured
    refStr = mat2str(refVals.', 6);                            % modulation from the single-source definition.

    set_param([mdl '/Rx Constellation'], 'ReferenceConstellation', refStr);    % Reference markers set; any
                                                               % failure is raised, not swallowed silently.

    readBack = strtrim(get_param([mdl '/Rx Constellation'], 'ReferenceConstellation'));

    assert(strcmp(readBack, strtrim(refStr)), ...              % The setting is confirmed by read-back.
        'Reference constellation read-back does not match the intended %s points.', cfg.modulation);

    fprintf('Repair 1 OK: Rx Constellation reference set to the %d unit-power %s points, verified by read-back.\n', ...
        numel(refVals), cfg.modulation);
else
    fprintf('Repair 1 skipped: no Rx Constellation scope in the model.\n');
end


%% Repair two, on-model documentation of the profile-aware sweep:
%%

staleText = ['sweep_snr_grid verifies the compact 4x4 reference bench only; it refuses to run under the ' ...
             'massive profile. The massive reference results come from run_massive_mimo in MATLAB.'];

currentText = ['sweep_snr_grid follows the active simulation profile: under the compact profile it verifies ' ...
               'the 4x4 reference bench against the locked compact vectors, and under the massive profile it ' ...
               'sweeps the massive grid and verifies this bench against matlab_results_massive.csv written by ' ...
               'run_massive_mimo, storing simulink_results_massive.csv beside the model.'];

anns = find_system(mdl, 'FindAll', 'on', 'Type', 'annotation');            % All annotations of the model.

fixedAnn = false;                                  % One annotation carries the stale sweep paragraph.
for a = anns.'
    txt = get_param(a, 'Text');                    % Annotation text of this handle.
    if contains(txt, 'refuses to run under the massive profile')           % The stale paragraph is identified
        txt = strrep(txt, staleText, currentText);                         % by its unique wording and replaced;
        if contains(txt, 'refuses to run under the massive profile')       % a partial match falls back to a
            txt = strrep(txt, 'refuses to run under the massive profile', ...       % sentence-level correction.
                'follows the active profile and verifies the massive bench against matlab_results_massive.csv');
        end
        set_param(a, 'Text', txt);                 % Corrected documentation written back.
        fixedAnn = true;
    end
end

if fixedAnn
    fprintf('Repair 2 OK: on-model sweep documentation updated to the profile-aware behavior.\n');
else
    fprintf('Repair 2 skipped: no annotation with the stale sweep paragraph was found.\n');
end


%% Save:
%%

save_system(mdl);                                  % Save the repaired model in place.

fprintf('Model %s.slx saved. Results, blocks, and layout are unchanged.\n', mdl);
