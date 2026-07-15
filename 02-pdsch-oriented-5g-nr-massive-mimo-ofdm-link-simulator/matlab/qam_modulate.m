
%%
function symbols = qam_modulate(bits, modulation)
%% Vectorized QAM Bit-to-Symbol Mapping:
%%
%{
The qam_modulate function maps a bit sequence to unit-power Gray-coded QAM symbols using a fully vectorized lookup.
The bit-tuple-to-symbol map is precomputed as a table indexed by the decimal value of each bit tuple with the most
significant bit first, the input bits are reshaped into tuples, each tuple is converted to its index by a single
matrix product with the binary weights, and the symbols are produced by one indexed read, so no per-symbol search is
performed.

Input:

    bits                          Bit sequence whose length is a multiple of the bits per symbol.
    modulation                    Modulation name: QPSK, 16QAM, 64QAM, or 256QAM.

Output:

    symbols                       Complex unit-average-power QAM symbol column vector.
%}
%% Constellation and input validation:
%%

[tuples, vals, bps] = qam_constellation(modulation);   % Shared constellation definition of the selected order.
bits = uint8(bits(:));                             % Column bit vector for the tuple reshape.
if mod(length(bits),bps) ~= 0                      % The bit count must fill whole symbols.
    error('Bit length must be multiple of bits/symbol');
end


%% Lookup table indexed by the tuple decimal value:
%%

M = 2^bps;                                         % Constellation size of the selected order.
lut = complex(zeros(M,1));                         % Symbol table indexed by the tuple value.
keys = tuples * (2.^(bps-1:-1:0)).';               % Decimal key of every bit tuple, MSB first.
lut(keys+1) = vals;                                % Table filled in constellation order.


%% Vectorized mapping:
%%

B = reshape(double(bits), bps, []).';              % One bit tuple per row.
idx = B * (2.^(bps-1:-1:0)).';                     % Tuple decimal values by one matrix product.
symbols = lut(idx+1);                              % All symbols produced by one indexed read.
end
