
%% 
function out = append_crc24a(payloadBits, cfg)
%% CRC24A Attachment:
%%
%{
The append_crc24a function attaches the CRC24A parity to a transport-block payload by concatenating the payload bits
with the twenty-four parity bits computed over them, in the attachment order of TS 38.212.

Input:

    payloadBits                   Transport-block payload bits.
    cfg.crcPoly                   CRC24A generator polynomial.

Output:

    out                           Payload bits followed by the twenty-four parity bits.
%}
out = [uint8(payloadBits(:)); crc24a(uint8(payloadBits(:)), cfg.crcPoly)];   % Payload followed by its parity.
end
