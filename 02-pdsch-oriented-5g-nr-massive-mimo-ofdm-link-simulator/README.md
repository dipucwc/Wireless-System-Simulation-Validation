# PDSCH-Oriented 5G NR Massive MIMO-OFDM Link-Level Simulator

**Design, Implementation, Verification, and Performance Evaluation of a PDSCH-Oriented 5G NR Massive MIMO-OFDM Physical Layer Link-Level Simulator**

This technical report is a wireless physical-layer engineering portfolio project. It implements and documents a **PDSCH-oriented 5G NR Massive MIMO-OFDM link-level simulator** using MATLAB, Python, and a Simulink system-level architecture.

The project focuses on the digital baseband PHY chain for downlink PDSCH-style transmission: transmitter processing, MIMO channel modeling, receiver processing, DM-RS-based channel estimation, ZF/MMSE equalization, metric computation, and verification.

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

## Repository Structure

```text
Project01_PDSCH_5G_NR_Massive_MIMO_OFDM_Link_Simulator/
│
├── README.md
├── TECHNICAL_SCOPE.md
├── REPOSITORY_STRUCTURE.md
├── GITHUB_UPLOAD_STEPS.md
├── LICENSE
├── .gitignore
│
├── 01_Report/
│   ├── Technical_Report.docx
│   ├── Technical_Report.pdf
│   └── figures/
│
├── 02_MATLAB/
│   ├── main.m
│   ├── config.m
│   ├── transmitter/
│   ├── receiver/
│   ├── channel/
│   ├── mimo/
│   ├── estimation/
│   ├── equalization/
│   ├── metrics/
│   └── visualization/
│
├── 03_Python/
│   ├── main.py
│   ├── config.py
│   ├── transmitter/
│   ├── receiver/
│   ├── channel/
│   ├── mimo/
│   ├── estimation/
│   ├── equalization/
│   ├── metrics/
│   └── visualization/
│
├── 04_Simulation_Results/
│   ├── MATLAB/
│   │   ├── csv/
│   │   └── figures/
│   └── Python/
│       ├── csv/
│       └── figures/
│
└── 05_Simulink/
    ├── build_project01_simulink_model.m
    ├── run_project01_simulink.m
    ├── models/
    ├── matlab_core/
    ├── screenshots/
    └── docs/
```

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

where `G[k] = H[k]W[k]` is the effective channel after digital precoding.

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

## Author

**Md Moklesur Rahman**  
Wireless/RF/PHY System Engineering Portfolio  
GitHub: [dipucwc](https://github.com/dipucwc)

---

## Citation

```text
Md Moklesur Rahman, "PDSCH-Oriented 5G NR Massive MIMO-OFDM Link-Level Simulator: MATLAB, Python, and Simulink-Based PHY Design and Verification," GitHub engineering portfolio project.
```

