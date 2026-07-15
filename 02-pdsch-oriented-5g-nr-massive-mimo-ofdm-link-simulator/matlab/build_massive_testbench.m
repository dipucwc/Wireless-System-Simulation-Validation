%%
%%
% Massive MIMO Test Bench Builder:
%%
%{
The build_massive_testbench script turns the Simulink test bench into the massive MIMO configuration of the project,
sixty-four transmit antennas, eight receive antennas, and four spatial layers with wideband eigen-beamforming on the
flat Rayleigh channel, in one command. It first backs up the current compact model file so the annotated four-by-four
bench is never lost, then selects the massive profile so that config, and therefore every Simulink wrapper, returns
the massive parameters, rebuilds the model so that every MATLAB Function block is regenerated with the massive signal
dimensions, and attaches the RF monitoring branch. The rebuilt model carries the dimension-derived title 5G NR PDSCH
64x8 MIMO-OFDM Link-Level Test Bench, a stop time of fifty-nine for the sixty frames of the massive profile, and the
identical verified processing chain; the verification gates still execute before the first step. The interpreted
sixty-four-antenna eigendecomposition per frame makes the massive bench noticeably slower than the compact one, which
is expected. To return to the compact reference bench, run set_sim_profile('compact') followed by
build_nr_pdsch_simulink, or restore the backup file.

Auxiliary functions:

    set_sim_profile               Persistent profile switch read by config everywhere.
    build_nr_pdsch_simulink       Model builder deriving all block dimensions from config.
    add_rf_measurements           Passive RF monitoring branch on the rebuilt model.

Output:

    NR_PDSCH_LinkLevel_Sim_4x4_backup.slx     Backup of the previous compact model, when one exists.
    NR_PDSCH_LinkLevel_Sim.slx                Rebuilt 64x8 massive test bench with the monitoring branch.
%}


%% Backup of the current compact model:
%%

if exist('NR_PDSCH_LinkLevel_Sim.slx', 'file')     % Preserve the annotated compact bench before rebuilding.
    if bdIsLoaded('NR_PDSCH_LinkLevel_Sim')
        close_system('NR_PDSCH_LinkLevel_Sim', 0); % Close a loaded copy without saving.
    end
    copyfile('NR_PDSCH_LinkLevel_Sim.slx', 'NR_PDSCH_LinkLevel_Sim_4x4_backup.slx');
    fprintf('Backed up the current model to NR_PDSCH_LinkLevel_Sim_4x4_backup.slx\n');
end


%% Massive profile selection:
%%

set_sim_profile('massive');                        % config now returns 64x8, L = 4 everywhere, wrappers included.


%% Rebuild with regenerated block dimensions and attach the monitoring branch:
%%

build_nr_pdsch_simulink;                           % All MATLAB Function block sizes regenerated at 64x8.

add_rf_measurements;                               % Passive waveform branch on the massive bench.

fprintf(['\nMassive 64x8 test bench ready. Run it with the green Run button.\n' ...
         'Return to the compact reference bench with:\n' ...
         '    set_sim_profile(''compact''); build_nr_pdsch_simulink\n' ...
         'or restore NR_PDSCH_LinkLevel_Sim_4x4_backup.slx.\n']);
