
%% 
function W = dft_precoder(nTx, nLayers)
%% Fixed Unitary DFT Precoder:
%%
%{
The dft_precoder function returns a fixed unitary precoder whose columns are the first columns of the normalized DFT
matrix of the transmit array size. The columns are orthonormal, so the total-transmit-power convention of the channel
application holds without further scaling. This precoder is an additional fixed baseline of the simulator.

Input:

    nTx                           Number of transmit antennas.
    nLayers                       Number of spatial layers.

Output:

    W                             Unitary precoder of size nTx x nLayers.
%}
n = (0:nTx-1).'; k = 0:nTx-1;                      % Row and column indices of the DFT matrix.
F = exp(-1j*2*pi*(n*k)/nTx)/sqrt(nTx);             % Normalized DFT matrix with orthonormal columns.
W = F(:,1:nLayers);                                % First columns as the fixed precoder.
end
