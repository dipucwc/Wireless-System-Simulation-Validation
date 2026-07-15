%%
%%
% Simulation Profile Switch:
%%
%{
The set_sim_profile function selects the simulation profile that config returns by default, by writing the profile
name to the sim_profile.txt file in the project folder. Because every simulator function and every Simulink wrapper
reads its parameters through config, the selected profile takes effect everywhere at once: in the MATLAB scripts, in
the tests, and in the Simulink testbench. The compact profile is the verification configuration behind the reference
results; the massive profile is the executed 64x8 four-layer eigen-beamforming configuration of the massive MIMO
comparison. After switching the profile, the Simulink testbench must be rebuilt with build_nr_pdsch_simulink so that
the fixed block signal dimensions are regenerated for the new antenna and layer counts, followed by
add_rf_measurements when the monitoring branch is wanted.

Input:

    name                          Profile name: 'compact' or 'massive'.

Output:

    sim_profile.txt               Profile file read by config; removed when the compact default is selected.
%}

function set_sim_profile(name)

name = lower(strtrim(name));                       % Case-insensitive profile name.

if ~any(strcmp(name, {'compact','massive'}))       % Only the two defined profiles are accepted.
    error('Unknown profile: %s (use compact or massive)', name);
end


%% Write or remove the profile file:
%%

if strcmp(name, 'compact')                         % The compact default needs no profile file.
    if exist(fullfile(pwd,'sim_profile.txt'),'file')
        delete(fullfile(pwd,'sim_profile.txt'));
    end
    fprintf('Profile: compact (4x4, L = 2, TDL reference configuration).\n');
else
    fid = fopen(fullfile(pwd,'sim_profile.txt'),'w');          % Persistent switch read by config.
    fprintf(fid, 'massive');
    fclose(fid);
    fprintf('Profile: massive (64x8, L = 4, wideband SVD, flat Rayleigh).\n');
end

fprintf(['Rebuild the Simulink testbench for the new dimensions:\n' ...
         '    build_nr_pdsch_simulink\n' ...
         'then add_rf_measurements for the monitoring branch.\n']);
end
