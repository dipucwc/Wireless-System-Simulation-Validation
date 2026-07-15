
%% 
function [dmrsMask, dmrsValues, dataPositions] = sl_layout()
%% Deterministic Frame Layout for the Simulink Testbench:
%%
%{
The sl_layout function returns the deterministic frame layout, the DM-RS mask, the Gold-seeded pilot values, and the
data positions, shared by the receiver blocks of the Simulink testbench. The layout of build_frame is independent of
the random payload, so the random-generator state is saved and restored around the probe call to keep the Monte Carlo
stream intact.

Output:

    dmrsMask                      Logical DM-RS position mask per layer.
    dmrsValues                    Deterministic DM-RS QPSK values per layer.
    dataPositions                 Symbol and subcarrier indices of every data resource element.
%}

cfg = config();
s = rng; f = build_frame(cfg); rng(s);             % State save and restore keeps the Monte Carlo stream intact.
dmrsMask = f.dmrsMask; dmrsValues = f.dmrsValues; dataPositions = f.dataPositions;
end
