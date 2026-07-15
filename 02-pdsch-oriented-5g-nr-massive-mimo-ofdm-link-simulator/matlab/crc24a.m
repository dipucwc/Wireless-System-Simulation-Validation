
%% 
function crcBits = crc24a(bits, poly)
%% CRC24A Parity Computation:
%%
%{
The crc24a function computes the CRC24A parity bits of a bit sequence using the TS 38.212 generator polynomial. The
computation is a bit-serial linear feedback shift register over the lower twenty-four bits of the polynomial: for
every input bit the feedback is formed as the exclusive-or of the register's most significant bit with the input, the
register is shifted and masked to twenty-four bits, and the polynomial is added on feedback. The parity word is
emitted most significant bit first, matching the attachment order used on the transport block.

Input:

    bits                          Payload bit sequence.
    poly                          CRC24A generator polynomial.

Output:

    crcBits                       Twenty-four parity bits, most significant bit first.
%}
%% Shift-register update over the input bits:
%%

reg = uint32(0);                                   % Twenty-four-bit shift register.
for i = 1:length(bits)                             % One input bit per iteration.
    feedback = bitxor(bitget(reg,24), uint32(bits(i)));           % Feedback of the register MSB with the input bit.
    reg = bitand(bitshift(reg,1), uint32(hex2dec('FFFFFF')));     % Shift and mask to twenty-four bits.
    if feedback                                    % The polynomial is added on feedback.
        reg = bitxor(reg, uint32(poly));
    end
end


%% Parity word, MSB first:
%%

crcBits = zeros(24,1,'uint8');                     % Parity output in the attachment order.
for i = 1:24
    crcBits(i) = uint8(bitget(reg,25-i));          % Register bits emitted most significant first.
end
end
