
%% 
function frame = build_frame(cfg)
%% PDSCH Frame Construction:
%%
%{
The build_frame function constructs one PDSCH-like transmission frame. It first builds the layer-orthogonal DM-RS
mask by placing a frequency comb per layer on the configured DM-RS symbols, with the comb offset by the layer index
so that the pilots of different layers never collide; every resource element not used by any layer's pilots carries
data on all layers. The transport-block length is then derived so that the payload plus the CRC24A parity exactly
fills the available data resource elements at the configured modulation order. The payload is generated, the CRC24A
parity is attached, the block is scrambled with the NR Gold sequence initialized from the RNTI and the scrambling
identity, and the scrambled bits are mapped to unit-power Gray-coded QAM symbols. The DM-RS values are generated as
Gold-seeded unit-power QPSK symbols, deterministic per scrambling identity and layer, so the receiver can divide each
pilot observation by its known transmitted value. The data symbols are then written into the layer grid in
resource-element-first, layer-second order, a convention that the metric calculation reproduces exactly on the
receive side, the pilot values are inserted, and the function returns the frame structure containing the payload, the
CRC-attached and scrambled bit sequences, the layer grid, the DM-RS mask and values, and the data positions consumed
by the receiver.

Auxiliary functions:

    append_crc24a                 Attaches the CRC24A parity to the payload.
    scramble_bits                 Scrambles the CRC-attached block with the NR Gold sequence.
    qam_modulate                  Maps the scrambled bits to unit-power QAM symbols.
    nr_gold_sequence              Generates the deterministic DM-RS QPSK values per layer.

Input:

    cfg                           Complete simulation configuration structure.

Output:

    frame.payload                 Transport-block payload bits.
    frame.bitsCrc                 Payload bits with the CRC24A parity attached.
    frame.scrambledBits           Scrambled CRC-attached bit sequence.
    frame.layerGrid               Transmit layer grid of size nSymbols x nSC x nLayers.
    frame.dmrsMask                Logical DM-RS position mask per layer.
    frame.dmrsValues              Deterministic DM-RS QPSK values per layer.
    frame.dataMask                Logical mask of the data resource elements.
    frame.dataPositions           Symbol and subcarrier indices of every data resource element.
%}
%% DM-RS mask, comb pattern per layer on the configured DM-RS symbols:
%%

dmrsMask = false(cfg.nSymbols, cfg.nSC, cfg.nLayers);          % Pilot position mask per layer.
for m = cfg.dmrsSymbols                            % One DM-RS symbol per iteration.
    for layer = 1:cfg.nLayers
        dmrsMask(m, layer:cfg.dmrsSpacing:cfg.nSC, layer) = true;   % Comb offset by the layer index avoids collisions.
    end
end
pilotAny = any(dmrsMask,3);                        % Resource elements used by any layer's pilots.
dataMask = ~pilotAny;                              % Remaining resource elements carry data on all layers.
[mIdx,kIdx] = find(dataMask);                      % Symbol and subcarrier indices of the data elements.
dataPositions = [mIdx kIdx];                       % Data positions in the fixed transmitter order.
nDataRE = size(dataPositions,1);                   % Number of data resource elements per slot.


%% Transport-block sizing from the available data resource elements:
%%

totalQamSymbols = nDataRE * cfg.nLayers;           % QAM symbols carried by all layers.
codedBitsLen = totalQamSymbols * cfg.bitsPerSymbol;            % Bits carried by all data elements.
tbLen = codedBitsLen - cfg.crcLen;                 % The payload plus the parity fills the grid exactly.


%% Payload, CRC attachment, scrambling, and QAM mapping:
%%

payload = uint8(randi([0 1],tbLen,1));             % Random transport-block payload.
bitsCrc = append_crc24a(payload, cfg);             % Payload with the CRC24A parity attached.
scrambled = scramble_bits(bitsCrc, cfg);           % Gold-sequence scrambling of the CRC-attached block.
qamSymbols = qam_modulate(scrambled, cfg.modulation);          % Unit-power Gray QAM symbols.


%% Deterministic Gold-seeded QPSK DM-RS values per layer:
%%

dmrsValues = complex(zeros(cfg.nSymbols, cfg.nSC, cfg.nLayers));   % Pilot values per layer.
for layer = 1:cfg.nLayers
    [mp,kp] = find(dmrsMask(:,:,layer));           % Pilot positions of this layer.
    nPil = length(mp);                             % Pilot count of this layer.
    cInit = bitshift(uint32(cfg.nID),8) + uint32(layer);           % Deterministic per identity and layer.
    c = nr_gold_sequence(cInit, 2*nPil);           % Two Gold bits per pilot value.
    pil = (1-2*double(c(1:2:end)) + 1j*(1-2*double(c(2:2:end))))/sqrt(2);   % Unit-power QPSK pilot values.
    for p = 1:nPil
        dmrsValues(mp(p),kp(p),layer) = pil(p);    % Pilot value written at its position.
    end
end


%% Layer grid, data symbols in resource-element-first, layer-second order, then pilots:
%%

layerGrid = complex(zeros(cfg.nSymbols,cfg.nSC,cfg.nLayers));  % Transmit layer grid.
qidx = 1;                                          % Running QAM-symbol index.
for p = 1:nDataRE                                  % One data resource element per iteration.
    m = dataPositions(p,1); k = dataPositions(p,2);            % Position of this element.
    layerGrid(m,k,:) = reshape(qamSymbols(qidx:qidx+cfg.nLayers-1),1,1,[]);   % All layers of this element.
    qidx = qidx + cfg.nLayers;                     % Advance by one symbol per layer.
end
for layer = 1:cfg.nLayers                          % Pilot insertion after the data mapping.
    [mp,kp] = find(dmrsMask(:,:,layer));
    for p = 1:length(mp)
        layerGrid(mp(p),kp(p),layer) = dmrsValues(mp(p),kp(p),layer);   % Pilot written on its layer.
    end
end


%% Frame structure consumed by the receiver and the metric calculation:
%%

frame.payload = payload;                           % Transport-block payload bits.
frame.bitsCrc = bitsCrc;                           % CRC-attached bit sequence.
frame.scrambledBits = scrambled;                   % Scrambled transmit bit sequence.
frame.layerGrid = layerGrid;                       % Complete transmit layer grid.
frame.dmrsMask = dmrsMask;                         % Pilot position mask per layer.
frame.dmrsValues = dmrsValues;                     % Deterministic pilot values per layer.
frame.dataMask = dataMask;                         % Data resource-element mask.
frame.dataPositions = dataPositions;               % Data positions in the transmitter order.
end
