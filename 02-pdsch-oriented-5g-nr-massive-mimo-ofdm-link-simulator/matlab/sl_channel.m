
%%
function H = sl_channel(~)
%% Simulink Channel Wrapper:
%%
%{
The sl_channel function draws one independent channel realization per simulation step for the Simulink testbench
through generate_channel, using the channel model selected in the configuration.

Output:

    H                             Channel realization of size nSC x nRx x nTx.
%}

cfg = config();                                    % Locked simulation configuration.
H = generate_channel(cfg);                         % One independent channel realization.
end
