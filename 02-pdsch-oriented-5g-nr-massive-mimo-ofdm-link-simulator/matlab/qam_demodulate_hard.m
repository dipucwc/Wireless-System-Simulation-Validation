
%%
function bits = qam_demodulate_hard(symbols, modulation)
%% Vectorized Hard-Decision QAM Demapping:
%%
%{
The qam_demodulate_hard function performs minimum-Euclidean-distance hard demapping of equalized symbols in a fully
vectorized form. The squared distances between every received symbol and every constellation point are evaluated as
one matrix, the nearest point is selected per symbol, and the corresponding Gray-coded bit tuples are emitted in the
transmitter bit order, so the output bit stream is directly comparable with the scrambled transmit sequence.

Input:

    symbols                       Equalized complex symbol vector.
    modulation                    Modulation name: QPSK, 16QAM, 64QAM, or 256QAM.

Output:

    bits                          Recovered bit column vector in the transmitter bit order.
%}
%% Constellation:
%%

[tuples, vals, bps] = qam_constellation(modulation); %#ok<ASGLU>   % Shared definition of the selected order.


%% Nearest-point decision for all symbols at once:
%%

symbols = symbols(:);                              % Column symbol vector for the distance matrix.
d = abs(symbols - vals.').^2;                      % Squared distance from every symbol to every point.
[~, idx] = min(d, [], 2);                          % Minimum-distance constellation index per symbol.


%% Bit emission in tuple order:
%%

B = tuples(idx, :).';                              % Bit tuples of the decided points, tuple-major.
bits = uint8(B(:));                                % Bit stream in the transmitter bit order.
end
