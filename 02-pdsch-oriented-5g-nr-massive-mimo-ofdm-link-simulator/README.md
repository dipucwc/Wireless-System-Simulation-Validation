## Design, Implementation, Verification, and Performance Evaluation of a PDSCH-Oriented 5G NR Massive MIMO-OFDM Physical Layer Link-Level Simulator
# 5G NR PDSCH Massive MIMO-OFDM Link-Level Simulator

A verified, three-environment (MATLAB / Python / Simulink) physical-layer link-level simulator for the 3GPP 5G NR PDSCH, built around a 64×8 massive MIMO-OFDM configuration with wideband SVD eigenbeamforming, LS channel estimation, ZF/MMSE equalization, and a TS 38.212 LDPC coded mode.

Every curve and table in this repository comes from executed code: each campaign runs automated verification gates first, and each result is saved to a file that records exactly which script, configuration, and seed produced it.

**Full technical report:** [`Design_Implementation_Verification_and_Performance_Evaluation_of_a_PDSCH-Oriented_5G_NR_Massive_MIMO-OFDM_Physical_Layer_Link-Level_Simulator.docx`](./report/)

---

## Headline results (all executed and verified)

| Result | Value | Where |
|---|---|---|
| Massive MIMO beamforming gain, SVD 64×8 vs unprecoded 4×4, equal total Tx power | **19.6 dB at BER 10⁻¹**; error-free above 5 dB (zero errors in 1.7×10⁶ bits/point) | `run_massive_mimo.m`, report Section 11.7 |
| End-to-end 64×8 campaign (16-QAM, L = 4, flat Rayleigh, LS + MMSE) | BER 3.4×10⁻¹ → 1.1×10⁻⁴ over −10…10 dB; 55.248 Mbit/s and 12.789 bit/s/Hz from 15 dB | `main.m`, report Section 11.8 |
| MATLAB ↔ Python cross-verification | **35 / 35 comparisons PASS** (5 metrics × 7 SNR points, statistical tolerances) | `cross_verification_record_massive.txt`, report Section 11.8 |
| LDPC coded mode (TS 38.212, rates 0.3008 / 0.4785 / 0.7539) | Rate-ordered BLER waterfalls; exact throughput plateaus 8.960 / 14.336 / 22.544 Mbit/s | `run_ldpc_campaign*.m`, report Section 11.9 |
| Simulink testbench sweep vs MATLAB reference | **7 / 7 SNR points PASS** (worst dev: 0.063 dec BER, 0.47 % capacity) | `sweep_snr_grid.m`, report Section 11.10 |
| Waveform measurements (64 antennas × 60 frames @ 7.68 MHz) | 4.32 MHz occupied BW, ~28 dB OOB skirts; PAPR ≈ 9 dB @10 %, ≈ 10.3 dB @1 % | `plot_rf_measurements.m`, report Section 11.11 |

---

## What is implemented

**Transmitter**- CRC-24A transport block, Gold-sequence scrambling, QPSK/16/64/256-QAM mapping (TS 38.211 bit ordering), layer mapping, DM-RS insertion, wideband SVD eigenbeamforming precoder, CP-OFDM modulation (256-FFT, 30 kHz SCS, 12 RB verification numerology).

**Channel**- AWGN, flat Rayleigh, 3GPP TDL profiles; one independent realization per Monte Carlo frame; total-transmit-SNR noise calibration.

**Receiver**- LS channel estimation on DM-RS, ZF and unbiased MMSE equalization, demapping, descrambling, CRC check; soft-output path with per-RE noise variance for LDPC LLRs.

**Coded mode**- 5G Toolbox `nrDLSCH` encoder/decoder (segmentation, LDPC, rate matching) with `nrSymbolModulate`/`nrSymbolDemodulate`, on the verified chain.

**Metrics**- BER, BLER, EVM, NMSE, throughput, spectral efficiency, layer-domain capacity.

**Simulink testbench**- `NR_PDSCH_LinkLevel_Sim.slx`: one Monte Carlo frame per simulation step; five annotated stages; every MATLAB Function block is a thin `sl_*` wrapper around the verified project functions; live Spectrum Analyzer and Constellation Diagram; To-Workspace logging; automated SNR-grid sweep with pass/fail verdicts against the MATLAB reference CSV.

---

## Monte Carlo method

Each SNR point is estimated from independent random trials (60 frames for the massive campaign; 40/100 transport blocks for the coded grids). Every trial draws fresh random payload bits, a fresh channel realization, and fresh noise; metrics are counted/averaged over the trials. `rng(7)` is set once, so the complete experiment is exactly reproducible. Zero-error entries are reported as below the campaign's rule-of-three resolution (≈1.8×10⁻⁶ on 1.66×10⁶ bits/point), never extrapolated.

## Verification before any result

Four gates run automatically before every campaign and abort on failure:

1. Constellation power exactly 1 for all orders
2. Noiseless modulation round trip error-free
3. OFDM round-trip error at machine precision (1.19×10⁻¹⁵)
4. CRC-24A accepts valid and rejects corrupted blocks

The coded campaigns add gates L1–L3 (noiseless coded round trip + CRC, LLR sign convention, full-chain decode at 30 dB). Unit tests against closed-form theory: `test_awgn.m`, `test_awgn_theory.m` (ideal CSI within 0.007 decades of theory), `test_rayleigh_theory.m`.

---

## Repository structure

```
├── matlab_pkg/                  # primary implementation
│   ├── main.m                   # end-to-end 64×8 Monte Carlo campaign
│   ├── run_comparisons.m        # BER vs theory, ZF/MMSE, capacity, beamforming
│   ├── run_massive_mimo.m       # independent massive rerun + measured 19.6 dB gain
│   ├── run_ldpc_campaign.m      # coded campaign, 0:5:25 dB, 40 blocks/point
│   ├── run_ldpc_campaign_fine.m # coded campaign, 0:2.5:15 dB, 100 blocks/point
│   ├── config.m / set_sim_profile.m
│   ├── build_nr_pdsch_simulink.m / add_rf_measurements.m
│   ├── sweep_snr_grid.m         # Simulink sweep + verdicts vs MATLAB CSV
│   ├── plot_rf_measurements.m   # PSD, PAPR CCDF, constellation from logged waveform
│   ├── sl_*.m                   # thin Simulink wrappers around verified functions
│   ├── test_*.m                 # theory unit tests
│   └── NR_PDSCH_LinkLevel_Sim.slx
├── python_pkg/                  # independent reference implementation
│   └── cross_verify_csv.py      # MATLAB↔Python comparison, tolerance verdicts
├── 04_Simulation_Results/       # executed CSVs, config logs, saved figures
│   └── MATLAB/csv/matlab_results_massive.csv, ldpc_*.csv, ...
├── report/                      # the full technical report (docx/pdf)
└── README.md
```

*(Adjust paths above to the actual repo layout if it differs.)*

## Requirements

- MATLAB R2023b or later; **5G Toolbox** (coded mode only); **Simulink** + DSP System Toolbox scopes (testbench only). The uncoded MATLAB campaigns run on base MATLAB.
- Python 3.10+ with NumPy and Matplotlib for the reference implementation.

---

## Project Highlights

- PDSCH-oriented 5G NR downlink link-level simulation
- Massive MIMO-OFDM physical-layer modeling
- MATLAB implementation as the primary simulation path
- Python reference implementation using NumPy/SciPy/Matplotlib
- Simulink system-level architecture wrapper for visual and execution-flow verification
- AWGN, Rayleigh, Rician, and TDL-like channel models
- DM-RS-based LS/MMSE channel estimation
- ZF and MMSE MIMO equalization
- BER, BLER-like, EVM, NMSE, throughput, spectral efficiency, SINR, and capacity metrics
- Monte Carlo simulation with fixed random-seed control
- Technical report with equations, algorithms, diagrams, verification methodology, and design trade-offs

---

## Technical Scope

This is a **PDSCH-oriented research and portfolio simulator**, not a commercial 3GPP conformance test platform.

The simulator models the main PHY signal-processing flow:

```text
Transport bits
→ CRC / coding interface
→ scrambling
→ QAM mapping
→ layer mapping
→ digital precoding
→ OFDM resource-grid generation
→ MIMO wireless channel + AWGN
→ DM-RS channel estimation
→ ZF/MMSE equalization
→ demodulation and metric computation
```

The project is intended for PHY algorithm understanding, link-level simulation practice, receiver-algorithm comparison, MIMO-OFDM performance evaluation, MATLAB/Python verification workflow, and GitHub engineering portfolio demonstration.

---

## MATLAB Simulation

MATLAB is used as the primary simulation and-verification platform.

```matlab
cd('02_MATLAB')
main
```

Expected outputs:

```text
04_Simulation_Results/MATLAB/csv/
04_Simulation_Results/MATLAB/figures/
```

The MATLAB implementation should generate BER, BLER or frame-error metric, EVM, NMSE, throughput, and MIMO capacity results.

---

## Python Reference Simulation

Python is used as an independent numerical reference implementation.

```bash
cd 03_Python
python main.py
```

Install dependencies:

```bash
pip install numpy scipy matplotlib pandas
```

Expected outputs:

```text
04_Simulation_Results/Python/csv/
04_Simulation_Results/Python/figures/
```

The Python implementation checks tensor organization, QAM normalization, channel/noise scaling, equalizer behavior, metric definitions, and MATLAB/Python numerical agreement.

---

## Simulink System-Level Model

The Simulink model provides a system-level architecture view and execution-flow wrapper around MATLAB algorithm functions.

```matlab
cd('05_Simulink')
build_project01_simulink_model
run_project01_simulink
```

Important boundary:

> Full native Simulink PHY blocks are not included. The Simulink model is a system-level architecture and wrapper around MATLAB-core numerical processing.

---

## Main Algorithms

### Effective MIMO channel model

```text
y[k] = G[k] s[k] + n[k]
```
where `G[k]  is the effective channel after digital precoding.

### Channel estimation

The receiver estimates the effective channel using DM-RS symbols. LS estimation is performed per DM-RS resource element and per separated DM-RS port/layer.

### Equalization

The simulator supports:

- Zero-Forcing equalization
- MMSE equalization

### Metrics

The simulator computes BER, BLER-like frame-error ratio, EVM, NMSE, throughput, spectral efficiency, post-equalization SINR, and MIMO capacity.

---

## Verification Strategy

The verification approach follows four levels:

1. Unit verification of each processing module.
2. Analytical verification using AWGN BER and MIMO capacity references where available.
3. MATLAB/Python cross-check under the same configuration and random seed.
4. Regression verification using stored CSV outputs.

---

## Technical Boundaries

This repository does **not** claim to be a full 3GPP conformance test system.

Not included in the baseline scope:

- MAC/RLC/PDCP/RRC
- scheduling
- HARQ protocol timing
- mobility and handover
- core-network procedures
- RF impairments such as phase noise, IQ imbalance, PA nonlinearity, DPD, ADC/DAC quantization
- full native block-by-block Simulink PHY implementation
- commercial-grade 3GPP conformance validation

---

## Report

The full technical report is located in:

```text
01_Report/Technical_Report.pdf
01_Report/Technical_Report.docx
```

The report includes requirements, architecture, mathematical foundations, end-to-end system model, channel models, signal-processing algorithms, MATLAB/Python implementations, verification methodology, simulation-result generation workflow, engineering design trade-offs, conclusion, and future work.

---

---

##  GitHub Topics

```text
5g-nr
pdsch
massive-mimo
ofdm
wireless-communications
physical-layer
link-level-simulation
matlab
python
simulink
dmrs
channel-estimation
zf-equalization
mmse-equalization
mimo-ofdm
```

---
## Quick start

```matlab
cd matlab_pkg
main                    % gates -> 64×8 campaign -> matlab_results_massive.csv + Figures
run_comparisons         % theory checks, ZF/MMSE, capacity, beamforming gain
run_ldpc_campaign       % coded BLER/throughput (requires 5G Toolbox)
open NR_PDSCH_LinkLevel_Sim   % set SNR (dB) block, Stop Time 59, Run
sweep_snr_grid          % full Simulink sweep + verdicts vs MATLAB reference
```

## Reproducibility

Configuration is locked and logged (`matlab_results_massive_config.txt`), the seed is fixed, results are written to CSV before plotting, and every figure in the report regenerates from a stored file plus the source code. Two independent MATLAB runs and the Python implementation agree within Monte Carlo tolerances — the disagreement pattern itself (exact match on deterministic columns, spread only on random-error columns) is part of the verification evidence.

## Scope

Physical-layer link level only: no MAC scheduling, HARQ protocol timing, or higher-layer procedures; RF impairments (phase noise, IQ imbalance, PA nonlinearity) are deliberately outside the verified core and form the extension roadmap, starting from the measured PAPR.

## Author

**Md Moklesur Rahman** — Senior RF/PHY Engineer (5G NR PHY algorithms: beamforming & calibration, channel estimation, equalization, massive MIMO, OFDM)
LinkedIn: [md-moklesur-rahman](https://www.linkedin.com/in/md-moklesur-rahman-65a63962) · GitHub: [dipucwc](https://github.com/dipucwc)

## License

Code: MIT (see `LICENSE`). Report and figures: © Md Moklesur Rahman, all rights reserved- cite the report if you reference the results.

---

## Citation

```text
Md Moklesur Rahman, "PDSCH-Oriented 5G NR Massive MIMO-OFDM Link-Level Simulator: MATLAB, Python, and Simulink-Based PHY Design and Verification," GitHub engineering portfolio project.
```

