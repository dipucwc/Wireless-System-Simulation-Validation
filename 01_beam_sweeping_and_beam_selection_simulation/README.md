
## Project Status

> **Ongoing project- currently under development**

This project is being developed as a MATLAB- and Python-based simulation framework for studying **beam sweeping, beam measurement, and beam selection in directional wireless communication systems**.

The repository is currently a work in progress. The implementation, simulation results, figures, validation records, and documentation will be added and updated as development continues.

---

## Overview

Directional wireless systems use antenna arrays and beamforming to concentrate transmitted or received energy in selected spatial directions. Before communication can begin efficiently, the transmitter and receiver may need to search through a predefined set of candidate beams, measure the received signal quality for each beam pair, and select the most suitable beam.

This project will simulate that process through:

- transmit-beam sweeping;
- receive-beam sweeping;
- beam-pair measurement;
- beam-quality comparison;
- best-beam selection;
- performance evaluation under different channel and noise conditions;
- MATLAB and Python cross-checking.

The project is intended as an engineering simulation and verification study rather than a complete standards-conformance implementation.

---

## Main Objectives

The main objectives of this project are to:

1. model directional transmission using uniform linear arrays or uniform planar arrays;
2. generate configurable transmit and receive beam codebooks;
3. sweep candidate transmit and receive beam directions;
4. calculate the received signal level or beamforming gain for every beam pair;
5. select the beam pair that maximizes a defined quality metric;
6. evaluate beam-selection accuracy under noise, angular mismatch, multipath, and blockage;
7. compare exhaustive and reduced-complexity beam-search strategies;
8. verify the main numerical results independently in MATLAB and Python;
9. present the complete workflow with clear figures, tables, and technical documentation.

---

## Technical Scope

### Antenna-Array Modeling

For a uniform linear array (ULA) with \(N\) antenna elements and inter-element spacing \(d\), the normalized steering vector is

$$
\mathbf{a}(\theta)
=
\frac{1}{\sqrt{N}}
\begin{bmatrix}
1 \\
e^{j2\pi \frac{d}{\lambda}\sin(\theta)} \\
\vdots \\
e^{j2\pi (N-1)\frac{d}{\lambda}\sin(\theta)}
\end{bmatrix}.
$$

Here:

- \(N\) is the number of antenna elements;
- \(d\) is the spacing between adjacent antenna elements;
- \(\lambda\) is the carrier wavelength;
- \(\theta\) is the propagation or beam-steering angle measured from the array broadside;
- \(j=\sqrt{-1}\) is the imaginary unit.

The normalization factor \(1/\sqrt{N}\) ensures that

$$
\left\|\mathbf{a}(\theta)\right\|_2^2 = 1.
$$

The sign of the phase progression may be reversed depending on the transmit/receive and angle conventions used in the implementation. MATLAB and Python will use the same convention.

---

### Beam Codebook

The transmitter and receiver use finite beam codebooks defined as

$$
\mathcal{F}
=
\left\{
\mathbf{f}_1,
\mathbf{f}_2,
\ldots,
\mathbf{f}_{N_{\mathrm{TX}}}
\right\},
$$

and

$$
\mathcal{W}
=
\left\{
\mathbf{w}_1,
\mathbf{w}_2,
\ldots,
\mathbf{w}_{N_{\mathrm{RX}}}
\right\}.
$$

Here:

- \(\mathbf{f}_i\) is the beamforming vector of the \(i\)-th transmit beam;
- \(\mathbf{w}_j\) is the combining vector of the \(j\)-th receive beam;
- \(N_{\mathrm{TX}}\) is the number of candidate transmit beams;
- \(N_{\mathrm{RX}}\) is the number of candidate receive beams.

For steering-vector-based codebooks, the beamforming and combining vectors can be defined as

$$
\mathbf{f}_i
=
\mathbf{a}_{\mathrm{TX}}(\theta_i),
\qquad
i=1,2,\ldots,N_{\mathrm{TX}},
$$

and

$$
\mathbf{w}_j
=
\mathbf{a}_{\mathrm{RX}}(\phi_j),
\qquad
j=1,2,\ldots,N_{\mathrm{RX}},
$$

where \(\theta_i\) and \(\phi_j\) are the candidate transmit and receive beam directions.

The initial implementation will use uniformly spaced beam directions over a configurable angular search region. Additional codebook designs may be added later.

---

### Directional Channel Model

For transmit beam \(i\) and receive beam \(j\), the received reference signal is modeled as

$$
y_{i,j}
=
\mathbf{w}_j^{H}
\mathbf{H}
\mathbf{f}_i s
+
\mathbf{w}_j^{H}\mathbf{n},
$$

where:

- \(y_{i,j}\) is the received signal for beam pair \((i,j)\);
- \(\mathbf{H}\) is the MIMO channel matrix;
- \(\mathbf{f}_i\) is the \(i\)-th transmit beamforming vector;
- \(\mathbf{w}_j\) is the \(j\)-th receive combining vector;
- \(s\) is the known transmitted reference symbol;
- \(\mathbf{n}\) is the complex additive-noise vector;
- \((\cdot)^H\) denotes the Hermitian transpose.

The scalar effective channel associated with beam pair \((i,j)\) is

$$
h_{\mathrm{eff}}(i,j)
=
\mathbf{w}_j^{H}
\mathbf{H}
\mathbf{f}_i.
$$

The project will initially use a line-of-sight directional channel. Later versions may include multipath propagation, angular spread, path loss, shadowing, blockage, mobility, and beam misalignment.

---

### Beam Measurement

For every candidate transmit–receive beam pair, the receiver calculates a beam-quality metric. Possible metrics include:

- received reference-signal power;
- effective beamforming gain;
- signal-to-noise ratio;
- signal-to-interference-plus-noise ratio.

The ideal noise-free beam-pair gain is

$$
G_{i,j}
=
\left|
\mathbf{w}_j^{H}
\mathbf{H}
\mathbf{f}_i
\right|^2.
$$

When the transmitted reference symbol has unit energy, a practical received-power measurement can be calculated as

$$
P_{i,j}
=
\left|y_{i,j}\right|^2.
$$

The first metric isolates the channel and beamforming response, whereas the second includes the effects of measurement noise.

---

### Best-Beam Selection

Using the ideal beam-pair gain, the selected transmit and receive beam indices are

$$
\left(i^{\star},j^{\star}\right)
=
\underset{
\substack{
1\leq i\leq N_{\mathrm{TX}}\\
1\leq j\leq N_{\mathrm{RX}}
}
}{
\operatorname{arg\,max}
}
\;
G_{i,j}.
$$

For noisy beam measurements, the practical selection rule becomes

$$
\left(\widehat{i},\widehat{j}\right)
=
\underset{
\substack{
1\leq i\leq N_{\mathrm{TX}}\\
1\leq j\leq N_{\mathrm{RX}}
}
}{
\operatorname{arg\,max}
}
\;
P_{i,j}.
$$

The simulation will compare the selected beam pair with the ideal beam pair and with the true channel departure and arrival directions. This comparison will be used to calculate the correct-beam-selection probability, angular selection error, and beam quantization loss.

---

### Planned End-to-End Workflow
---

## Planned End-to-End Workflow

1. Define the carrier frequency and wavelength.
2. Configure the transmit and receive antenna arrays.
3. Generate the transmit and receive beam codebooks.
4. Generate the directional wireless channel.
5. Transmit a known reference signal.
6. Sweep all configured transmit beams.
7. Sweep all configured receive beams.
8. Calculate the selected beam-quality metric for every beam pair.
9. Create the beam-pair measurement matrix.
10. Select the strongest beam pair.
11. Compare the selected beam with the true propagation direction.
12. Repeat the experiment over multiple noise and channel realizations.
13. Calculate performance metrics.
14. Generate figures and result tables.
15. Compare MATLAB and Python outputs.

---

## Planned Simulation Scenarios

### Scenario 1: Ideal Single-Path Channel

- one dominant propagation path;
- no blockage;
- perfect array calibration;
- configurable additive noise;
- exhaustive beam search.

This scenario will verify the basic beam-sweeping and beam-selection logic.

### Scenario 2: Beam-Direction Mismatch

- the true departure or arrival angle falls between two codebook directions;
- beam quantization loss is evaluated;
- different codebook sizes are compared.

### Scenario 3: Low-SNR Beam Selection

- beam measurements are corrupted by noise;
- correct-beam-selection probability is evaluated versus SNR;
- repeated Monte Carlo trials are used.

### Scenario 4: Multipath Channel

- several paths have different gains and angles;
- the strongest measured beam may differ from the geometric line-of-sight direction;
- selection is evaluated using the combined channel response.

### Scenario 5: Blockage or Beam Failure

- the currently selected path is attenuated or removed;
- the system performs another beam sweep;
- recovery using an alternative beam is evaluated.

### Scenario 6: Reduced-Complexity Search

- exhaustive search is compared with hierarchical or two-stage search;
- search overhead and selection accuracy are evaluated jointly.

---

## Planned Performance Metrics

| Metric | Purpose |
|---|---|
| Maximum received beam power | Measures the strength of the selected beam pair |
| Beamforming gain | Quantifies array gain relative to an unsteered reference |
| Selected-beam index | Identifies the chosen transmit and receive beams |
| Angular selection error | Measures the difference between selected and true directions |
| Correct-beam-selection probability | Measures beam-selection reliability |
| Top-\(K\) selection probability | Checks whether the correct beam is among the strongest candidates |
| Post-beamforming SNR | Measures signal quality after beam selection |
| Beam-search overhead | Counts the number of tested beam pairs |
| Beam quantization loss | Measures loss caused by finite codebook resolution |
| MATLAB–Python deviation | Verifies numerical consistency between implementations |
| Runtime | Compares computational complexity of search strategies |

---

## Planned Figures

The completed project is expected to include:

- transmit-array radiation pattern;
- receive-array radiation pattern;
- beam-codebook angular coverage;
- beam-pair power heatmap;
- selected beam compared with the true direction;
- received power versus beam index;
- correct-selection probability versus SNR;
- angular error versus codebook size;
- beamforming gain versus angular mismatch;
- exhaustive-search overhead versus hierarchical-search overhead;
- MATLAB and Python result comparison.

---

## MATLAB and Python Implementation

The MATLAB and Python implementations will follow the same antenna-array dimensions, angle convention, steering-vector definition, beam-codebook directions, channel coefficients, noise normalization, beam-quality metric, selection rule, Monte Carlo configuration, and result definitions.

Because MATLAB and Python may use different random-number generators, numerical verification will use deterministic channels, fixed beam codebooks, known test vectors, stage-by-stage comparisons, and tolerance-based checks of the final selected beam.

---

## Planned Verification Tests

| Verification test | Purpose | Current status |
|---|---|---|
| Steering-vector norm | Verify unit-norm array response | Planned |
| Beamformer norm | Verify equal transmit-power normalization | Planned |
| Broadside response | Verify expected phase progression at broadside | Planned |
| Symmetry check | Verify expected ULA beam-pattern symmetry | Planned |
| Noiseless correct-beam test | Verify correct selection in an ideal channel | Planned |
| Beam-index boundary test | Verify first and last codebook directions | Planned |
| Power-matrix dimension test | Verify transmit-beam × receive-beam dimensions | Planned |
| MATLAB–Python deterministic comparison | Verify common numerical conventions | Planned |
| Noise-sensitivity test | Verify selection performance degrades logically with SNR | Planned |
| Search-algorithm consistency | Verify exhaustive search gives the reference maximum | Planned |

---

## Current Development Status

- [x] Project topic defined
- [x] Initial repository created
- [x] Technical scope identified
- [ ] System requirements finalized
- [ ] MATLAB antenna-array model implemented
- [ ] Python antenna-array model implemented
- [ ] Beam codebook implemented
- [ ] Directional channel model implemented
- [ ] Exhaustive beam-sweeping algorithm implemented
- [ ] Beam-selection algorithm implemented
- [ ] Monte Carlo simulation implemented
- [ ] Verification tests completed
- [ ] MATLAB–Python cross-verification completed
- [ ] Result figures generated
- [ ] Final technical report completed

This checklist will be updated as the project progresses.

---

## Planned Repository Structure

```text
Beam-Sweeping-and-Beam-Selection-Simulation/
├── README.md
├── matlab/
│   ├── main_beam_sweeping.m
│   ├── config.m
│   ├── generate_steering_vector.m
│   ├── generate_beam_codebook.m
│   ├── generate_directional_channel.m
│   ├── evaluate_beam_pairs.m
│   ├── select_best_beam.m
│   ├── run_monte_carlo.m
│   └── verify_simulation.m
├── python/
│   ├── main_beam_sweeping.py
│   ├── config.py
│   ├── steering_vector.py
│   ├── beam_codebook.py
│   ├── directional_channel.py
│   ├── beam_pair_evaluation.py
│   ├── beam_selection.py
│   ├── monte_carlo.py
│   └── verification.py
├── results/
│   ├── figures/
│   ├── tables/
│   └── csv/
├── verification/
│   ├── deterministic_vectors/
│   └── comparison_results/
├── docs/
│   └── technical_report/
└── LICENSE
```

The filenames shown above are a proposed organization and may change during development.

---

## Software Requirements

The final MATLAB implementation is expected to require:

- MATLAB;
- optional Phased Array System Toolbox;
- optional Communications Toolbox.

The Python implementation is expected to use:

- Python 3;
- NumPy;
- SciPy;
- Matplotlib;
- pandas;
- optional pytest for automated verification.

A final dependency file will be added when the implementation is stable.

---

## How to Run

The project is not yet ready for complete execution. Final commands will be added after the executable implementation is stable.

Planned Python command:

```bash
python python/main_beam_sweeping.py
```

Planned MATLAB command:

```matlab
run("matlab/main_beam_sweeping.m")
```

---

## Expected Engineering Outcome

The completed project is expected to demonstrate:

- how directional codebook beams cover an angular search region;
- how transmit and receive beam sweeping creates a beam-pair measurement matrix;
- how beam selection depends on SNR, array size, codebook resolution, and channel direction;
- why a larger codebook can reduce angular quantization loss but increase search overhead;
- how noise and multipath can cause incorrect beam selection;
- how hierarchical search can reduce overhead with a possible loss in selection accuracy;
- how MATLAB and Python can be used for independent model verification.

No final performance claim is made at the current development stage.

---

## Initial Model Limitations

The first version is expected to use a simplified physical-layer model. Possible initial limitations include:

- narrowband beamforming;
- ideal phase shifters;
- perfect array calibration;
- no mutual coupling;
- no RF nonlinearities;
- simplified path-loss and channel models;
- ideal synchronization;
- no complete 3GPP beam-management procedure;
- no hardware or over-the-air validation.

These limitations will be documented clearly and extended gradually where useful.

---

## Future Extensions

Possible future extensions include:

- 5G NR synchronization-signal-block beam sweeping;
- CSI-RS-based beam refinement;
- beam reporting and beam-failure recovery;
- wideband OFDM beam squint;
- hybrid analog–digital beamforming;
- planar-array azimuth and elevation search;
- mobility and beam tracking;
- blockage modeling;
- multi-user beam selection;
- interference-aware beam selection;
- machine-learning-assisted beam prediction;
- practical phase-shifter quantization;
- RF impairments and array-calibration error;
- measured or ray-tracing channel data;
- hardware-in-the-loop or over-the-air validation.

---

## Contribution

This is currently an individual engineering simulation project under active development. Suggestions, technical comments, and issue reports may be added through GitHub after the first executable version is released.

---

## License

A license will be selected before the source code is publicly released. Until a `LICENSE` file is added, the project should be treated as **all rights reserved**.

---

## Author

**Md Moklesur Rahman**  
Wireless/RF/PHY System Engineer  
Finland

---

## Notice

This README describes the planned project scope. Features marked as planned have not yet been presented as completed or verified. The README will be updated as implementation, verification, and result generation progress.
