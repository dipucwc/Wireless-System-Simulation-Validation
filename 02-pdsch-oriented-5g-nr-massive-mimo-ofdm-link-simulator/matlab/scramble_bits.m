
%%
function out = scramble_bits(bits, cfg)
%% NR Gold-Sequence Bit Scrambling:
%%
%{
The scramble_bits function scrambles a bit sequence by exclusive-or with the NR Gold sequence, with the
initialization value formed from the RNTI and the scrambling identity in the TS 38.211 form. The operation is an
involution, so the identical call performs descrambling at the receiver.

Input:

    bits                          Bit sequence to scramble or descramble.
    cfg.rnti                      RNTI entering the sequence initialization.
    cfg.nID                       Scrambling identity entering the sequence initialization.

Output:

    out                           Scrambled or descrambled bit sequence.
%}
cInit = bitshift(uint32(cfg.rnti),15) + uint32(cfg.nID);   % Initialization value from the RNTI and the identity.
seq = nr_gold_sequence(cInit, length(bits));               % Gold sequence of the input length.
out = bitxor(uint8(bits(:)), seq);                         % Exclusive-or scrambling; the identical call descrambles.
end
