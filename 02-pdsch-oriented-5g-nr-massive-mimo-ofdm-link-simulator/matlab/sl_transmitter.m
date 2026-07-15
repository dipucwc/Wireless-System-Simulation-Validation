
%% 
function [layerGrid, bitsCrc] = sl_transmitter(~)
%% Simulink Transmitter Wrapper:
%%
%{
The sl_transmitter function generates one PDSCH frame per simulation step for the Simulink testbench: transport
block, CRC24A, Gold scrambling, unit-power Gray QAM, layer mapping, and DM-RS insertion through build_frame.

Output:

    layerGrid                     Transmit layer grid of the frame.
    bitsCrc                       CRC-attached bit sequence as double for the Simulink signal path.
%}

cfg = config();                                    % Locked simulation configuration.
f = build_frame(cfg);                              % One complete PDSCH frame.
layerGrid = f.layerGrid;                           % Transmit layer grid of the frame.
bitsCrc = double(f.bitsCrc);                       % Reference bits as double for the signal path.
end
