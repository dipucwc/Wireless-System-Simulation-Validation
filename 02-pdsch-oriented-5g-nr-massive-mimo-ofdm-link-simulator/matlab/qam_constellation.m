
%%
function [tuples, vals, bps] = qam_constellation(modulation)
%% Gray-Mapped QAM Constellation Definitions:
%%
%{
The qam_constellation function is the single source of the Gray-mapped constellation definitions shared by the
modulator and the demodulator, covering QPSK through 256-QAM. For each rectangular order the in-phase and quadrature
axes use a Gray-coded bit-to-level map, the constellation is formed as the Cartesian product of the two axes with the
in-phase bits first, and the points are normalized to unit average power with the standard factors of the square root
of two, ten, forty-two, and one hundred seventy. Defining the constellation in one place guarantees that mapping and
demapping can never disagree on the bit-to-symbol convention.

Input:

    modulation                    Modulation name: QPSK, 16QAM, 64QAM, or 256QAM.

Output:

    tuples                        Bit tuples of every constellation point, one row per point.
    vals                          Complex unit-average-power constellation values, one per row of tuples.
    bps                           Number of bits per symbol of the selected order.
%}
modulation = upper(modulation);                    % Case-insensitive modulation selection.


%% Per-order axis definitions:
%%

switch modulation
    case 'QPSK'
        bps = 2;                                   % Two bits per QPSK symbol.
        tuples = [0 0; 0 1; 1 1; 1 0];             % Gray bit tuples of the four points.
        vals = [1+1j; 1-1j; -1-1j; -1+1j] / sqrt(2);   % Unit-power QPSK values.
        return
    case '16QAM'
        bps = 4;                                   % Four bits per 16-QAM symbol.
        axisBits = [0 0; 0 1; 1 1; 1 0];           % Gray bit map of one axis.
        axisVals = [-3 -1 1 3]; nrm = sqrt(10);    % Axis levels and unit-power normalization.
    case '64QAM'
        bps = 6;                                   % Six bits per 64-QAM symbol.
        axisBits = [0 0 0;0 0 1;0 1 1;0 1 0;1 1 0;1 1 1;1 0 1;1 0 0];   % Gray bit map of one axis.
        axisVals = [-7 -5 -3 -1 1 3 5 7]; nrm = sqrt(42);               % Axis levels and normalization.
    case '256QAM'
        bps = 8;                                   % Eight bits per 256-QAM symbol.
        axisBits = [0 0 0 0;0 0 0 1;0 0 1 1;0 0 1 0;0 1 1 0;0 1 1 1;0 1 0 1;0 1 0 0; ...
                    1 1 0 0;1 1 0 1;1 1 1 1;1 1 1 0;1 0 1 0;1 0 1 1;1 0 0 1;1 0 0 0];   % Gray bit map of one axis.
        axisVals = -15:2:15; nrm = sqrt(170);      % Axis levels and normalization.
    otherwise
        error('Unsupported modulation');
end


%% Cartesian product of the I and Q axes:
%%

nAxis = length(axisVals);                          % Points per axis of the square constellation.
tuples = zeros(nAxis*nAxis, bps);                  % Bit tuples of all constellation points.
vals = complex(zeros(nAxis*nAxis,1));              % Complex values of all constellation points.
n = 1;
for i = 1:nAxis                                    % In-phase axis index.
    for q = 1:nAxis                                % Quadrature axis index.
        tuples(n,:) = [axisBits(i,:) axisBits(q,:)];   % In-phase bits first, then quadrature bits.
        vals(n) = (axisVals(i) + 1j*axisVals(q))/nrm;  % Unit-average-power normalization.
        n = n + 1;
    end
end
end
