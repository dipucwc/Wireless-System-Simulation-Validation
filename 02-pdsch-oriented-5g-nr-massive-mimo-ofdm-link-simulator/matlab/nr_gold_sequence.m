
%%
function c = nr_gold_sequence(cInit, len)
%% NR Gold Pseudo-Random Sequence:
%%
%{
The nr_gold_sequence function generates the length-31 Gold pseudo-random sequence of TS 38.211. The first m-sequence
is initialized with a single leading one and the second is initialized from the thirty-one bits of the supplied
initialization value; both sequences are advanced with their defining recurrences, the first sixteen hundred outputs
are discarded per the specification, and the requested number of output bits is formed as the exclusive-or of the two
sequences. The function serves both the bit scrambling and the generation of the DM-RS QPSK values.

Input:

    cInit                         Thirty-one-bit sequence initialization value.
    len                           Number of output bits.

Output:

    c                             Gold sequence bits of the requested length.
%}
%% Sequence buffers and initialization:
%%

Nc = 1600;                                         % Specification offset discarded before the first output bit.
total = len + Nc + 31;                             % Buffer length covering the offset and the register span.
x1 = zeros(total,1,'uint8');                       % First m-sequence buffer.
x2 = zeros(total,1,'uint8');                       % Second m-sequence buffer.
x1(1) = 1;                                         % First sequence initialized with a single leading one.
for i = 1:31
    x2(i) = uint8(bitget(uint32(cInit), i));       % Second sequence initialized from the initialization value.
end


%% Recurrences of the two m-sequences:
%%

for n = 1:(total-31)
    x1(n+31) = bitxor(x1(n+3), x1(n));                                       % First-sequence recurrence.
    x2(n+31) = bitxor(bitxor(bitxor(x2(n+3), x2(n+2)), x2(n+1)), x2(n));     % Second-sequence recurrence.
end


%% Gold combination with the offset applied:
%%

c = bitxor(x1(Nc+1:Nc+len), x2(Nc+1:Nc+len));      % Output bits as the exclusive-or of the two sequences.
end
