
%% 
function ok = check_crc24a(bitsWithCrc, cfg)
%% CRC24A Verification:
%%
%{
The check_crc24a function verifies a received CRC-attached block by recomputing the CRC24A parity over the received
payload portion and comparing it with the received parity bits; the boolean result is the block-error decision of the
receiver.

Input:

    bitsWithCrc                   Received payload bits followed by the received parity bits.
    cfg.crcPoly                   CRC24A generator polynomial.
    cfg.crcLen                    CRC24A parity length in bits.

Output:

    ok                            True when the recomputed parity matches the received parity.
%}
payload = bitsWithCrc(1:end-cfg.crcLen);           % Received payload portion of the block.
rxCrc = bitsWithCrc(end-cfg.crcLen+1:end);         % Received parity bits.
ok = isequal(crc24a(payload, cfg.crcPoly), uint8(rxCrc(:)));   % Accept when the recomputed parity matches.
end
