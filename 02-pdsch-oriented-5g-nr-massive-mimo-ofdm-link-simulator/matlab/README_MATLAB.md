# MATLAB PDSCH-Oriented MIMO and Massive MIMO-OFDM Link-Level Simulator

## Project Information

| Item | Details |
|---|---|
| **Author** | Md Moklesur Rahman |
| **Project Type** | 5G NR physical-layer link-level simulation and verification |
| **Implementation** | MATLAB and Simulink |
| **Technical Scope** | PDSCH-oriented MIMO-OFDM, single-user 64×8 Massive MIMO, four spatial layers, SVD eigenbeamforming, DM-RS-based LS estimation, ZF/MMSE equalization, and Monte Carlo performance evaluation |
| **Email** | moklesur.eee@gmail.com |
| **LinkedIn** | [Md Moklesur Rahman](https://www.linkedin.com/in/md-moklesur-rahman-65a63962/) |
| **GitHub** | [dipucwc](https://github.com/dipucwc) |
| **Repository Area** | Wireless system simulation and validation |
| **Status** | Completed and verified single-user 64×8 Massive MIMO implementation with reproducible MATLAB/Simulink results and performance plots |

---

## Overview

This package provides a modular MATLAB and Simulink implementation of a
PDSCH-oriented MIMO and Massive MIMO-OFDM physical-layer link-level
simulator.

The project supports algorithm development, end-to-end verification,
Monte Carlo performance evaluation, MATLAB/Python cross-verification, and
profile-driven Simulink test-bench generation.

Two execution profiles are provided:

| Profile | Antenna Configuration | Spatial Layers | Primary Use |
|---|---:|---:|---|
| `compact` | 4 transmit × 4 receive | 2 | Fast end-to-end verification, regression testing, and baseline result generation |
| `massive` | 64 transmit × 8 receive | 4 | Report-aligned single-user Massive MIMO evaluation with SVD eigenbeamforming |

The Massive MIMO profile implements the 64×8, four-layer comparison
presented in report Section 11.7 and Figure 26.

The executed MATLAB and Simulink campaigns use a compact 12-RB resource
grid with 144 active subcarriers and a 256-point FFT to reduce simulation
time while preserving the complete 64×8, four-layer Massive MIMO
signal-processing chain. The report also defines a full 100 MHz FR1
reference configuration with 273 resource blocks and a 4096-point FFT.

---

## Main Features

The package includes:

- CRC24A attachment and checking
- NR Gold-sequence scrambling and descrambling
- Gray-coded QPSK, 16-QAM, 64-QAM, and 256-QAM
- Multi-layer resource-grid construction
- Gold-seeded QPSK DM-RS generation
- Identity, DFT, MRT, wideband SVD, and per-subcarrier SVD precoding
- AWGN, flat Rayleigh, per-subcarrier Rayleigh, Rician, and configurable TDL channels
- Ideal effective-channel knowledge
- DM-RS-based least-squares channel estimation
- Zero-forcing and unbiased-MMSE equalization
- BER, BLER, EVM, NMSE, throughput, spectral efficiency, and capacity
- Reproducible Monte Carlo simulation with controlled random seeds
- MATLAB and Simulink result generation
- Configuration logging beside saved CSV results
- Analytical BER and MIMO-capacity comparisons
- Compact and 64×8 Massive MIMO Simulink test-bench generation

---

## Implemented Configurations

### Compact Verification Profile

The compact profile uses:

```text
FFT size:              256
Active subcarriers:    144
Resource blocks:       12
Transmit antennas:     4
Receive antennas:      4
Spatial layers:        2
```

This profile is designed for fast debugging, verification-gate execution,
regression testing, and repeatable end-to-end evaluation.

### Massive MIMO Profile

The completed Massive MIMO profile uses:

```text
Transmit antennas:     64
Receive antennas:      8
Spatial layers:        4
Precoder:              Wideband SVD eigenbeamforming
Channel:               Flat Rayleigh
Equalizer:             MMSE
SNR range:             -10:5:20 dB
Frames per SNR point:  60
```

The corresponding matrix dimensions are:

```text
Physical channel H[k]:     8 × 64
Precoder W:               64 × 4
Effective channel G[k]:    8 × 4
Layer vector s[k]:         4 × 1
Transmit vector x[k]:     64 × 1
Receive vector y[k]:       8 × 1
```

This configuration is a fully digital, single-user Massive MIMO
link-level implementation.

---

## Processing Architecture

The implemented baseband flow is:

```text
Payload generation
    → CRC24A attachment
    → Gold-sequence scrambling
    → Gray-coded QAM mapping
    → Layer mapping
    → Digital precoding
    → Resource-grid and DM-RS construction
    → MIMO channel and AWGN
    → Ideal or LS effective-channel knowledge
    → ZF or unbiased-MMSE equalization
    → Hard QAM demapping
    → Descrambling
    → CRC verification
    → BER / BLER / EVM / NMSE / throughput / capacity evaluation
```

---

## Quick Start

Set the MATLAB **Current Folder** to the project root before running any
script.

### Run the Compact End-to-End Campaign

```matlab
set_sim_profile('compact');
main;
```

`main.m` performs the following steps:

1. Loads the compact configuration.
2. Initializes the random seed.
3. Runs all verification gates.
4. Sweeps the configured SNR values.
5. Executes the complete transmitter, channel, receiver, and metric chain.
6. Saves numerical results to CSV.
7. Writes a matching configuration log.
8. Generates the seven primary performance figures.

### Run the Comparison Campaigns

```matlab
run_comparisons;
```

This script generates:

- AWGN BER versus closed-form theory
- Flat-Rayleigh QPSK BER versus the analytical reference
- ZF versus MMSE equalization
- Ideal CSI versus LS-estimated CSI
- Ergodic capacity for 2×2, 4×4, and 8×8 MIMO
- Equalized 16-QAM constellations
- Unprecoded 4×4 versus SVD-precoded 64×8 Massive MIMO

The 64×8 result corresponds to report Section 11.7 and Figure 26.

### Run the Dedicated Massive MIMO Campaign

```matlab
run_massive_mimo;
```

This command runs the completed 64×8, four-layer Massive MIMO
configuration and stores the reference results in:

```text
matlab_results_massive.csv
matlab_results_massive_config.txt
```

The result set includes:

- BER
- BLER
- EVM
- NMSE
- capacity
- antenna configuration
- layer count
- executed SNR points

### Select the Active Profile

```matlab
set_sim_profile('compact');
set_sim_profile('massive');
```

A configuration can also be selected explicitly:

```matlab
cfg = config('compact');
cfg = config('massive');
```

Use an explicit profile inside scripts that must remain independent of the
current project state.

---

## Simulink Test-Bench Workflow

The Simulink model is generated from the active configuration profile.
Parameters that change signal dimensions require the model to be rebuilt.

### Build the Compact 4×4 Test Bench

```matlab
set_sim_profile('compact');
build_nr_pdsch_simulink;
open_system('NR_PDSCH_LinkLevel_Sim');
```

### Build the 64×8 Massive MIMO Test Bench

```matlab
set_sim_profile('massive');
build_nr_pdsch_simulink;
open_system('NR_PDSCH_LinkLevel_Sim');
```

The generated model title is derived from the selected antenna dimensions.
The Massive MIMO build therefore identifies the test bench as a 64×8
configuration.

### Complete Massive MIMO Simulink Verification

Run the following commands in order:

```matlab
run_massive_mimo;
build_massive_testbench;
sweep_snr_grid;
```

This workflow performs:

1. Massive MIMO MATLAB reference generation
2. Profile selection
3. 64×8 Simulink model rebuilding
4. Simulink execution over the configured SNR grid
5. Comparison against the saved MATLAB reference
6. Storage of the Massive MIMO Simulink result CSV

The sweep checks that the Simulink model dimensions match the active
profile before execution.

### Restore the Compact Test Bench

```matlab
set_sim_profile('compact');
build_nr_pdsch_simulink;
```

Rebuilding regenerates the model from the selected profile. Keep a backup
when manually added layout changes or annotations must be preserved.

---

## Simulink Rebuild Rules

### Dimension-Preserving Settings

The following settings can normally be changed without rebuilding:

- channel model
- equalizer type
- random seed
- Rician K-factor
- TDL tap delays and powers
- SNR value

### Dimension-Changing Settings

The following settings require a model rebuild:

- number of transmit antennas
- number of receive antennas
- number of spatial layers
- modulation order
- FFT size
- number of active subcarriers
- number of OFDM symbols
- DM-RS allocation

After changing any of these settings, run:

```matlab
build_nr_pdsch_simulink;
```

---

## MIMO Signal Model

For subcarrier \(k\), the transmitted antenna-domain vector is:

\[
\mathbf{x}[k]
=
\mathbf{W}[k]\mathbf{s}[k]
\]

The received signal is:

\[
\mathbf{y}[k]
=
\mathbf{H}[k]\mathbf{W}[k]\mathbf{s}[k]
+
\mathbf{n}[k]
\]

The effective layer-domain channel is:

\[
\mathbf{G}[k]
=
\mathbf{H}[k]\mathbf{W}[k]
\]

where:

- \(\mathbf{s}[k]\) is the layer-symbol vector
- \(\mathbf{W}[k]\) is the digital precoding matrix
- \(\mathbf{H}[k]\) is the physical MIMO channel
- \(\mathbf{G}[k]\) is the effective channel
- \(\mathbf{n}[k]\) is complex receiver noise

---

## SNR and Power Convention

The simulator uses total transmitted SNR.

With unit-power layers and unit-norm precoder columns:

\[
P_{\mathrm{TX,total}} = L
\]

where \(L\) is the number of spatial layers.

The complex receiver-noise variance is:

\[
\sigma_n^2
=
\frac{L}
{10^{\mathrm{SNR}_{\mathrm{dB}}/10}}
\]

MATLAB implementation:

```matlab
noiseVar = nLayers / 10^(snrDb/10);
```

The noise variance is fixed for each SNR point rather than being derived
from the instantaneous received signal power. This preserves the fading
statistics and allows array and beamforming gain to appear correctly in
the performance results.

The 4×4 and 64×8 comparison uses:

- four layers in both branches
- equal total transmitted power
- the same modulation
- the same SNR definition
- the same receiver type

The random seed is reset before both branches to make each run
reproducible. Because the matrix dimensions differ, the channel and noise
realizations are not element-by-element identical.

---

## Precoding

### Wideband SVD Eigenbeamforming

The default `svd` mode uses the dominant eigenvectors of the average
transmit-side channel covariance:

\[
\mathbf{R}
=
\frac{1}
{N_{\mathrm{SC}}}
\sum_k
\mathbf{H}^{H}[k]\mathbf{H}[k]
\]

The selected eigenvectors form a precoder that remains constant across the
active subcarriers.

This wideband implementation preserves the frequency smoothness required
by comb-type DM-RS interpolation.

### Per-Subcarrier SVD

The `svd_persc` mode calculates an independent precoder on every
subcarrier. It is available for ideal-CSI analysis.

On frequency-selective channels, independent singular-vector phase changes
can make the effective channel non-smooth across frequency. For this
reason, wideband SVD is used for the LS-estimated end-to-end campaign.

### Additional Precoding Modes

The package also provides:

- `identity` for unprecoded spatial multiplexing
- DFT precoding as a fixed unitary baseline
- MRT for single-layer transmission

The equalizer comparison uses identity precoding. This exposes
inter-layer interference and provides a meaningful comparison between ZF
and MMSE.

---

## Channel Models

### AWGN

The AWGN mode uses an identity channel and adds complex receiver noise. It
is used for analytical and end-to-end verification.

### Flat Rayleigh

`rayleigh_flat` generates one complex Gaussian MIMO matrix per frame and
keeps it constant across all active subcarriers.

This model is used for the analytical flat-Rayleigh BER comparison and
the 64×8 Massive MIMO campaign.

### Per-Subcarrier Rayleigh

`rayleigh_iid` generates an independent MIMO matrix on every subcarrier.
It provides a frequency-selective verification case.

### Rician

The Rician model combines deterministic line-of-sight and random
non-line-of-sight components using the configured K-factor.

### Configurable TDL

The TDL mode generates complex Rayleigh taps from the configured delays
and power-delay profile, transforms them to the frequency domain, and
normalizes the average channel power.

The implementation provides a configurable frequency-selective
tapped-delay model suitable for algorithm testing and verification.

---

## DM-RS and Channel Estimation

The DM-RS symbols are deterministic Gold-seeded QPSK values. Separate
sequences are generated from the configured scrambling identity and layer
index.

The least-squares estimate is calculated by dividing the received pilot by
its known transmitted value:

\[
\hat{\mathbf{G}}_{\mathrm{LS}}
=
\frac{\mathbf{Y}_{\mathrm{DMRS}}}
{\mathbf{X}_{\mathrm{DMRS}}}
\]

Pilot estimates are averaged across DM-RS symbols and interpolated over
the active subcarriers.

The receiver estimates the effective channel:

\[
\mathbf{G}[k]
=
\mathbf{H}[k]\mathbf{W}[k]
\]

This is the channel seen by the transmitted spatial layers after
precoding.

---

## Equalization

### Zero Forcing

The ZF equalizer is:

\[
\mathbf{F}_{\mathrm{ZF}}
=
\left(
\mathbf{G}^{H}\mathbf{G}
\right)^{-1}
\mathbf{G}^{H}
\]

or the corresponding pseudoinverse when required.

ZF removes inter-layer interference but may enhance noise when the channel
is ill-conditioned.

### Unbiased MMSE

The MMSE equalizer is:

\[
\mathbf{F}_{\mathrm{MMSE}}
=
\left(
\mathbf{G}^{H}\mathbf{G}
+
\sigma_n^2\mathbf{I}
\right)^{-1}
\mathbf{G}^{H}
\]

The raw MMSE output contains a layer-dependent amplitude bias. Before hard
QAM slicing, each layer is divided by the corresponding diagonal value of:

\[
\mathbf{F}_{\mathrm{MMSE}}\mathbf{G}
\]

The resulting unbiased-MMSE output is used for symbol detection.

---

## Performance Metrics

### Bit Error Rate

\[
\mathrm{BER}
=
\frac{N_{\mathrm{bit,error}}}
{N_{\mathrm{evaluated\ bits}}}
\]

### Block Error Rate

A block error is declared when the recovered CRC24A check fails:

\[
\mathrm{BLER}
=
\frac{N_{\mathrm{failed\ blocks}}}
{N_{\mathrm{transmitted\ blocks}}}
\]

### Error Vector Magnitude

\[
\mathrm{EVM}_{\mathrm{RMS}}
=
\sqrt{
\frac{
\sum |\hat{s}-s|^2
}{
\sum |s|^2
}
}
\]

### Channel-Estimation NMSE

\[
\mathrm{NMSE}
=
\frac{
\|\hat{\mathbf{G}}-\mathbf{G}\|_F^2
}{
\|\mathbf{G}\|_F^2
}
\]

### Layer-Domain Capacity

\[
C
=
\log_2
\det
\left(
\mathbf{I}
+
\frac{\rho}{L}
\mathbf{G}^{H}\mathbf{G}
\right)
\]

Capacity is used as a theoretical reference for the effective channel.

### Throughput

Successfully recovered payload bits are converted to Mbit/s using the
configured slot duration.

### Spectral Efficiency

Successful throughput is divided by the occupied bandwidth.

---

## Verification Gates

`run_verification_gates.m` executes before the primary campaign.

### Gate 1 — Constellation Power

The exhaustive constellation of every supported modulation order must
satisfy:

\[
E\{|s|^2\}=1
\]

### Gate 2 — Modulation Round Trip

A noiseless modulation-demodulation cycle must recover the original bits
exactly.

### Gate 3 — OFDM Round Trip

OFDM modulation followed by demodulation must reconstruct the input grid
at machine precision.

### Gate 4 — CRC24A Self-Test

The checker must:

- accept an intact CRC-protected block
- reject the same block after a deliberate bit corruption

The campaign stops immediately if any verification gate fails.

---

## Result Files and Figures

### Main Campaign

`main.m` generates:

1. BER
2. BLER
3. EVM
4. NMSE
5. Throughput
6. Spectral efficiency
7. Capacity

It also writes:

```text
<result_name>.csv
<result_name>_config.txt
```

### Comparison Campaign

`run_comparisons.m` generates:

1. AWGN BER versus theory
2. Flat-Rayleigh BER versus theory
3. ZF versus MMSE
4. MIMO capacity for several antenna configurations
5. Low- and high-SNR constellations
6. 4×4 versus 64×8 Massive MIMO

Zero-error BER points are omitted from logarithmic plots because
\(\log(0)\) is undefined. A zero-error point means that no error was
observed in the tested finite bit count.

---

## Recorded Verification Results

The following checks are documented from executed MATLAB and GNU Octave
runs:

- QPSK through 256-QAM constellations have unit average power
- noiseless modulation round trips recover the input bits
- OFDM round-trip error is at machine-precision level
- CRC24A accepts intact blocks and rejects corrupted blocks
- high-SNR AWGN SISO recovery produces zero observed BER and BLER
- simulated AWGN QPSK BER follows the analytical reference
- simulated flat-Rayleigh QPSK BER follows the analytical trend
- MMSE outperforms ZF in the unprecoded full-load comparison
- the 64×8 SVD-precoded branch provides a strong BER improvement over the
  unprecoded 4×4 branch at equal total transmitted power

A recorded 64×8 LS/MMSE frame at 10 dB used:

```text
H:       144 × 8 × 64
W:        64 × 4
rxGrid:   14 × 144 × 8
Ghat:    144 × 8 × 4
```

The same run recorded:

```text
BER:       3.62e-5
EVM:       0.104
NMSE:      1.27e-2
Capacity:  31.2 bit/s/Hz
```

These values correspond to the stated configuration, random seed, and
finite Monte Carlo run.

---

## BLER and Throughput Interpretation

The current compact end-to-end chain is uncoded and uses CRC24A for block
verification.

Because one block contains a large number of payload bits, BLER may remain
high until BER becomes very small. Throughput therefore rises mainly in
the higher-SNR region of the uncoded campaign.

This behavior is expected for the implemented uncoded verification chain.
The report separately discusses the coded PDSCH processing architecture.

---

## MATLAB and GNU Octave Compatibility

The numerical processing functions have been executed with GNU Octave 8.4.

`main.m` uses MATLAB table operations such as:

```matlab
struct2table
writetable
```

These output operations require MATLAB or an Octave-compatible
alternative.

Simulink model generation and execution require MATLAB with Simulink.

---

## Code-to-Report Mapping

| MATLAB Function | Report Model or Equation |
|---|---|
| `apply_mimo_channel` | \(\mathbf{y}=\mathbf{H}\mathbf{W}\mathbf{s}+\mathbf{n}\), equation (34) |
| `true_effective_channel` | Effective channel \(\mathbf{G}=\mathbf{H}\mathbf{W}\), equation (36) |
| `estimate_effective_channel_ls` | LS channel estimation, equation (65) |
| `equalize_mimo` | ZF equation (38), MMSE equation (39) |
| `compute_frame_metrics` | BER (41), BLER (42), EVM (43), NMSE (78) |
| `capacity_mimo` | Layer-domain capacity, equation (110) |
| `main` throughput calculation | Throughput (44), spectral efficiency (100) |
| `run_verification_gates` | Chapter 10 verification gates and OFDM round trip (89) |

---

## Main Files

| File | Purpose |
|---|---|
| `config.m` | Compact and Massive MIMO configuration profiles |
| `set_sim_profile.m` | Selects the active profile |
| `main.m` | Primary end-to-end campaign |
| `run_link_curve.m` | Shared Monte Carlo SNR-sweep engine |
| `run_comparisons.m` | Theory, equalizer, capacity, and Massive MIMO comparisons |
| `run_massive_mimo.m` | Dedicated 64×8 Massive MIMO campaign |
| `build_frame.m` | Payload, CRC, scrambling, modulation, layers, and DM-RS |
| `generate_channel.m` | AWGN, Rayleigh, Rician, and TDL channel generation |
| `compute_precoder.m` | Identity, DFT, MRT, and SVD precoding |
| `apply_mimo_channel.m` | Effective MIMO channel and receiver noise |
| `estimate_effective_channel_ls.m` | DM-RS-based LS estimation |
| `equalize_mimo.m` | ZF and unbiased-MMSE detection |
| `compute_frame_metrics.m` | BER, BLER, EVM, NMSE, throughput inputs, and capacity |
| `run_verification_gates.m` | Mandatory pre-campaign checks |
| `build_nr_pdsch_simulink.m` | Generates the active-profile Simulink model |
| `build_massive_testbench.m` | Builds and prepares the 64×8 Simulink test bench |
| `sweep_snr_grid.m` | Runs and verifies compact or Massive MIMO Simulink sweeps |

---

## Scope Boundaries

The completed implementation focuses on the PDSCH-oriented baseband
algorithms required for compact MIMO and single-user 64×8 Massive MIMO
link-level evaluation.

The following functions are natural extensions of the current modular
architecture:

- NR LDPC encoding and decoding
- code-block segmentation
- rate matching and rate recovery
- soft-output demodulation
- HARQ processing
- standardized 3GPP TDL-A/B/C/D/E profiles
- multi-user Massive MIMO
- spatially correlated array channels
- antenna geometry and mutual coupling
- hybrid analog-digital beamforming
- practical CSI feedback, quantization, and calibration
- RF impairments such as phase noise, IQ imbalance, and PA nonlinearity

---

## Author

**Md Moklesur Rahman**

- Email: moklesur.eee@gmail.com
- LinkedIn: [Md Moklesur Rahman](https://www.linkedin.com/in/md-moklesur-rahman-65a63962/)
- GitHub: [dipucwc](https://github.com/dipucwc)
