
%% Pre-Simulation Verification Gates:
%%
%{
The run_verification_gates function executes the four mandatory verification tests of the simulator before any
performance result can be generated, and aborts the calling script on the first failed assertion so that no simulation
can run on an unverified processing chain.

Gate one generates the exhaustive bit-pattern set of every supported modulation order, maps it through the modulator,
and asserts that the average constellation power equals one to within numerical precision, confirming the unit-power
normalization shared by the modulator and the demodulator.

Gate two performs the noiseless modulation round trip for every order by mapping a random bit sequence to symbols and
demapping it back, asserting bit-exact recovery, which confirms that the modulator and demodulator use one consistent
Gray mapping.

Gate three passes a random complex resource grid through the OFDM modulator and demodulator and asserts that the
maximum reconstruction error is at machine-precision level, confirming the unitary scaling of the transform pair.

Gate four attaches the CRC24A parity to a random payload and asserts that the checker accepts the intact block and
rejects the same block after a single-bit corruption, confirming both directions of the block-error decision.

Each passed gate prints a confirmation line, so every stored result is preceded by an executed gate record.

Auxiliary functions:

    qam_modulate
        Maps a bit sequence to unit-power Gray-coded QAM symbols.

    qam_demodulate_hard
        Performs minimum-distance hard demapping of QAM symbols back to bits.

    ofdm_modulate
        Converts the frequency-domain resource grid to the time-domain CP-OFDM waveform.

    ofdm_demodulate
        Converts the time-domain CP-OFDM waveform back to the frequency-domain resource grid.

    append_crc24a
        Attaches the CRC24A parity bits to a payload.

    check_crc24a
        Verifies a received CRC-attached block and returns the accept decision.

Input:

    cfg.nFFT                      FFT size of the OFDM grid.
    cfg.nSymbols                  Number of OFDM symbols per slot.
    cfg.nTx                       Number of transmit antennas.
    cfg.crcPoly                   CRC24A generator polynomial.
    cfg.crcLen                    CRC24A parity length in bits.

Output:

    Command Window                One confirmation line per passed gate.
    Assertion error               Raised on the first failed gate, stopping the calling script.
%}


function run_verification_gates(cfg)

fprintf('--- Verification gates ---\n');


%% Gate 1, constellation unit power for all supported orders:
%%

mods = {'QPSK','16QAM','64QAM','256QAM'};         % All supported modulation orders.

for i = 1:numel(mods)                              % One modulation order per iteration.
    bps = containers.Map(mods, {2,4,6,8});         % Bits per symbol of every order.
    b = bps(mods{i});                              % Bits per symbol of this order.
    M = 2^b;                                       % Constellation size of this order.

    bits = zeros(M*b,1,'uint8');               % Exhaustive bit patterns cover every constellation point once.
    for s = 0:M-1
        bits(s*b+(1:b)) = uint8(bitget(uint32(s), b:-1:1)).';
    end

    syms = qam_modulate(bits, mods{i});            % Every constellation point mapped exactly once.
    p = mean(abs(syms).^2);                    % Average power over the complete constellation set.

    assert(abs(p-1) < 1e-12, ...
        'Gate 1 FAILED: %s power %.3e', mods{i}, p);
end

fprintf('Gate 1 PASS: constellation power = 1 for all orders\n');


%% Gate 2, noiseless modulation round trip:
%%

for i = 1:numel(mods)                              % One modulation order per iteration.
    bps = containers.Map(mods, {2,4,6,8});         % Bits per symbol of every order.
    b = bps(mods{i});                              % Bits per symbol of this order.

    tb = uint8(randi([0 1], 120*b, 1));        % Random test bits for the mapping and demapping round trip.
    rb = qam_demodulate_hard(qam_modulate(tb, mods{i}), mods{i});   % Map and demap round trip.

    assert(isequal(tb, rb), ...
        'Gate 2 FAILED: %s round trip', mods{i});
end

fprintf('Gate 2 PASS: noiseless modulation round trip error-free\n');


%% Gate 3, OFDM round trip at machine precision:
%%

grid = (randn(cfg.nFFT,cfg.nSymbols,cfg.nTx) ...   % Random complex resource grid exercising the full transform pair.
      + 1j*randn(cfg.nFFT,cfg.nSymbols,cfg.nTx))/sqrt(2);

wf = ofdm_modulate(grid, cfg);                     % Grid to time-domain waveform.
g2 = ofdm_demodulate(wf, cfg, cfg.nTx);            % Waveform back to the grid.

err = max(abs(grid(:)-g2(:)));                 % Largest reconstruction error over the complete grid.

assert(err < 1e-12, ...
    'Gate 3 FAILED: OFDM round-trip error %.3e', err);

fprintf('Gate 3 PASS: OFDM round-trip error %.2e\n', err);


%% Gate 4, CRC24A accept and reject self-test:
%%

payload = uint8(randi([0 1], 200, 1));             % Random test payload.
blk = append_crc24a(payload, cfg);                 % CRC-attached test block.

assert(check_crc24a(blk, cfg), ...
    'Gate 4 FAILED: valid CRC rejected');

blk(17) = bitxor(blk(17), uint8(1));           % A single-bit corruption must be detected by the checker.

assert(~check_crc24a(blk, cfg), ...
    'Gate 4 FAILED: corrupted CRC accepted');

fprintf('Gate 4 PASS: CRC24A accepts valid and rejects corrupted blocks\n');

fprintf('--- All gates passed; simulation may run ---\n\n');

end
