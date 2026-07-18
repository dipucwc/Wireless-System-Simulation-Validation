# Beam Sweeping and Beam Selection Simulation

## Project Information

**Project type:** Wireless physical-layer simulation and verification  
**Implementation:** MATLAB and Python  
**Repository:** Wireless-System-Simulation-Validation  
**Project status:** Ongoing project — currently under development  
**Author:** Md Moklesur Rahman  


## Project Status

This project is currently under active development.

The repository will contain a MATLAB- and Python-based simulation framework for studying beam sweeping, beam measurement, beam-pair evaluation, and beam selection in directional wireless communication systems.

The implementation, verification scripts, simulation results, figures, result tables, and technical documentation will be added progressively as development continues. No final performance claim is made at the current stage.

## Overview

Directional wireless systems use antenna arrays and beamforming to concentrate transmitted and received energy in selected spatial directions. Before reliable communication can begin, the transmitter and receiver may need to search through predefined candidate beams, measure the quality of each transmit–receive beam pair, and select the beam pair that provides the strongest or most reliable link.

This project will simulate that process through:

- transmit-beam sweeping;
- receive-beam sweeping;
- beam-pair measurement;
- beam-quality comparison;
- best-beam selection;
- angular-error evaluation;
- beam quantization analysis;
- performance evaluation under different channel and noise conditions;
- exhaustive and reduced-complexity beam search;
- MATLAB and Python cross-verification.

The project is intended as an engineering simulation and validation study. It is not currently presented as a complete 3GPP standards-conformance implementation.

## Main Objectives

The main objectives are to:

1. model directional wireless transmission using configurable antenna arrays;
2. generate transmit and receive beam codebooks;
3. sweep candidate transmit and receive beam directions;
4. calculate received signal power or beamforming gain for every beam pair;
5. select the beam pair that maximizes a defined quality metric;
6. evaluate beam-selection accuracy under noise and angular mismatch;
7. study multipath, blockage, and beam-failure scenarios;
8. compare exhaustive and reduced-complexity beam-search methods;
9. measure the trade-off between codebook resolution and search overhead;
10. verify the numerical implementation independently in MATLAB and Python;
11. document the complete model, assumptions, algorithms, verification tests, and results.

## Technical Scope

The planned technical scope includes:

- uniform linear array modeling;
- optional uniform planar array modeling;
- transmit and receive steering-vector generation;
- configurable antenna count and element spacing;
- finite transmit and receive beam codebooks;
- line-of-sight and multipath directional channels;
- transmit and receive beam sweeping;
- beam-pair measurement matrices;
- ideal and noisy beam selection;
- Monte Carlo performance evaluation;
- correct-beam-selection probability;
- angular selection error;
- beam quantization loss;
- beam-search overhead;
- MATLAB–Python deterministic cross-verification.

## Antenna-Array Modeling

The initial model will use a uniform linear array. A uniform planar array may be added later for two-dimensional azimuth and elevation beam search.

For a uniform linear array with \(N\) antenna elements and inter-element spacing \(d\), the normalized steering vector is

$$
\mathbf{a}(\theta)=\frac{1}{\sqrt{N}}
\begin{bmatrix}
1 &
e^{j2\pi(d/\lambda)\sin(\theta)} &
\cdots &
e^{j2\pi(N-1)(d/\lambda)\sin(\theta)}
\end{bmatrix}^{T}.
$$

Here:

- \(N\) is the number of antenna elements;
- \(d\) is the spacing between adjacent antenna elements;
- \(\lambda\) is the carrier wavelength;
- \(\theta\) is the propagation or beam-steering angle measured from the array broadside;
- \(j=\sqrt{-1}\) is the imaginary unit;
- \((\cdot)^T\) denotes transpose.

The normalization factor \(1/\sqrt{N}\) gives a unit-norm steering vector:

$$
\left\|\mathbf{a}(\theta)\right\|_2^2=1.
$$

The phase sign may be positive or negative depending on the selected transmit, receive, and angular conventions. The MATLAB and Python implementations will use the same convention.

## Beam Codebook

The transmitter and receiver will use finite beam codebooks.

The transmit-beam codebook is

$$
\mathcal{F}=
\left\{
\mathbf{f}_1,
\mathbf{f}_2,
\ldots,
\mathbf{f}_{N_{\mathrm{TX}}}
\right\},
$$

and the receive-beam codebook is

$$
\mathcal{W}=
\left\{
\mathbf{w}_1,
\mathbf{w}_2,
\ldots,
\mathbf{w}_{N_{\mathrm{RX}}}
\right\}.
$$

Here:

- \(\mathbf{f}_i\) is the beamforming vector for transmit beam \(i\);
- \(\mathbf{w}_j\) is the combining vector for receive beam \(j\);
- \(N_{\mathrm{TX}}\) is the number of candidate transmit beams;
- \(N_{\mathrm{RX}}\) is the number of candidate receive beams.

For steering-vector-based codebooks,

$$
\mathbf{f}_i=\mathbf{a}_{\mathrm{TX}}(\theta_i),
\qquad
i=1,2,\ldots,N_{\mathrm{TX}},
$$

and

$$
\mathbf{w}_j=\mathbf{a}_{\mathrm{RX}}(\phi_j),
\qquad
j=1,2,\ldots,N_{\mathrm{RX}}.
$$

Here:

- \(\theta_i\) is the steering direction of transmit beam \(i\);
- \(\phi_j\) is the steering direction of receive beam \(j\).

The first implementation will use uniformly spaced steering directions over a configurable angular search range. Additional codebook designs may be studied later.

## Directional Channel Model

For transmit beam \(i\) and receive beam \(j\), the received reference signal is modeled as

$$
y_{i,j}=
\mathbf{w}_j^{H}
\mathbf{H}
\mathbf{f}_i s
+
\mathbf{w}_j^{H}\mathbf{n}.
$$

Here:

- \(y_{i,j}\) is the received signal for beam pair \((i,j)\);
- \(\mathbf{H}\) is the MIMO channel matrix;
- \(\mathbf{f}_i\) is the transmit beamforming vector;
- \(\mathbf{w}_j\) is the receive combining vector;
- \(s\) is the known transmitted reference symbol;
- \(\mathbf{n}\) is the complex additive-noise vector;
- \((\cdot)^H\) denotes Hermitian transpose.

The effective scalar channel associated with beam pair \((i,j)\) is

$$
h_{\mathrm{eff}}(i,j)=
\mathbf{w}_j^{H}
\mathbf{H}
\mathbf{f}_i.
$$

The initial implementation will use a line-of-sight directional channel. Later versions may include:

- multiple propagation paths;
- angular spread;
- path loss;
- log-normal shadowing;
- blockage;
- mobility;
- beam misalignment;
- interference;
- beam failure and recovery.

## Beam Measurement

For every transmit–receive beam pair, the receiver calculates a beam-quality metric.

Possible metrics include:

- received reference-signal power;
- effective beamforming gain;
- signal-to-noise ratio;
- signal-to-interference-plus-noise ratio;
- normalized beam score.

The ideal noise-free beam-pair gain is

$$
G_{i,j}=
\left|
\mathbf{w}_j^{H}
\mathbf{H}
\mathbf{f}_i
\right|^2.
$$

When the transmitted reference symbol has unit energy, the noisy received-power measurement is

$$
P_{i,j}=
\left|y_{i,j}\right|^2.
$$

The quantity \(G_{i,j}\) represents the ideal channel and beamforming response. The quantity \(P_{i,j}\) includes the effect of measurement noise.

## Best-Beam Selection

Using the ideal beam-pair gain, the best beam pair is

$$
(i^\star,j^\star)=
\operatorname*{arg\,max}_{1\leq i\leq N_{\mathrm{TX}},\;1\leq j\leq N_{\mathrm{RX}}}
G_{i,j}.
$$

Using noisy measurements, the practical beam-selection rule is

$$
(\widehat{i},\widehat{j})=
\operatorname*{arg\,max}_{1\leq i\leq N_{\mathrm{TX}},\;1\leq j\leq N_{\mathrm{RX}}}
P_{i,j}.
$$

Here:

- \((i^\star,j^\star)\) is the ideal best beam pair;
- \((\widehat{i},\widehat{j})\) is the beam pair selected from noisy measurements.

The simulation will compare the practical selection with the ideal beam pair and the true departure and arrival directions.

The comparison will be used to calculate:

- correct-beam-selection probability;
- angular selection error;
- beam quantization loss;
- received-power loss caused by an incorrect beam decision;
- top-\(K\) beam-selection probability.

## Planned End-to-End Workflow

1. Define the carrier frequency and wavelength.
2. Configure the transmit and receive antenna arrays.
3. Define the angular search region.
4. Generate the transmit beam codebook.
5. Generate the receive beam codebook.
6. Generate the directional wireless channel.
7. Generate a known reference signal.
8. Apply each candidate transmit beam.
9. Apply each candidate receive beam.
10. Calculate the beam-quality metric for every beam pair.
11. Store the measurements in a beam-pair matrix.
12. Identify the strongest beam pair.
13. Compare the selected beam pair with the ideal beam pair.
14. Calculate angular error and beam quantization loss.
15. Repeat the experiment over multiple channel and noise realizations.
16. Accumulate performance statistics.
17. Generate result tables and figures.
18. Compare MATLAB and Python outputs.
19. Apply verification checks before accepting the final results.

## Planned Simulation Scenarios

### Scenario 1: Ideal Single-Path Channel

The first scenario will verify the basic beam-sweeping and beam-selection logic using:

- one dominant propagation path;
- no blockage;
- perfect array calibration;
- configurable additive noise;
- exhaustive transmit–receive beam search.

### Scenario 2: Beam-Direction Mismatch

This scenario will study the case in which the true angle falls between two codebook directions.

The analysis will include:

- beam quantization error;
- received-power loss;
- angular selection error;
- comparison of different codebook sizes.

### Scenario 3: Low-SNR Beam Selection

This scenario will investigate beam-selection reliability when measurement noise is significant.

The analysis will include:

- correct-selection probability versus SNR;
- top-\(K\) beam-selection probability;
- selected-beam distribution;
- Monte Carlo confidence based on repeated trials.

### Scenario 4: Multipath Channel

This scenario will include several propagation paths with different gains and angles.

The strongest measured beam may differ from the geometric line-of-sight direction because the selected beam maximizes the combined channel response.

### Scenario 5: Blockage or Beam Failure

This scenario will attenuate or remove the currently dominant path.

The model will evaluate:

- loss of the current beam;
- repeated beam sweeping;
- alternative-beam selection;
- recovery time or search overhead.

### Scenario 6: Reduced-Complexity Beam Search

This scenario will compare exhaustive search with a hierarchical or two-stage search method.

The comparison will consider:

- number of tested beam pairs;
- beam-selection accuracy;
- angular error;
- received-power loss;
- computational runtime.

## Planned Performance Metrics

| Metric | Purpose |
|---|---|
| Maximum received beam power | Measures the strength of the selected beam pair |
| Beamforming gain | Quantifies directional array gain |
| Selected transmit-beam index | Identifies the chosen transmit beam |
| Selected receive-beam index | Identifies the chosen receive beam |
| Angular selection error | Measures the difference between selected and true directions |
| Correct-beam-selection probability | Measures beam-selection reliability |
| Top-\(K\) selection probability | Checks whether the correct beam is among the strongest candidates |
| Post-beamforming SNR | Measures signal quality after beam selection |
| Beam-search overhead | Counts the number of evaluated beam pairs |
| Beam quantization loss | Measures loss caused by finite codebook resolution |
| Received-power loss | Measures degradation caused by an incorrect beam decision |
| MATLAB–Python deviation | Measures cross-implementation numerical consistency |
| Runtime | Compares computational complexity of search methods |

## Planned Result Figures

The completed project is expected to include:

- transmit-array radiation pattern;
- receive-array radiation pattern;
- beam-codebook angular coverage;
- received power versus transmit-beam index;
- received power versus receive-beam index;
- two-dimensional beam-pair power matrix;
- selected beam compared with the true direction;
- correct-selection probability versus SNR;
- top-\(K\) selection probability versus SNR;
- angular error versus codebook size;
- beam quantization loss versus codebook size;
- beamforming gain versus angular mismatch;
- beam-search overhead comparison;
- exhaustive-search versus hierarchical-search performance;
- MATLAB and Python result comparison.

No images are included in the README while the project is still under development.

## MATLAB and Python Implementation

The MATLAB and Python implementations will use the same:

- antenna-array dimensions;
- inter-element spacing;
- carrier frequency;
- wavelength;
- angular convention;
- steering-vector definition;
- transmit and receive codebook directions;
- channel coefficients;
- noise normalization;
- beam-quality metric;
- beam-selection rule;
- Monte Carlo configuration;
- performance metrics;
- result definitions.

Because MATLAB and Python may use different random-number generators, numerical verification will not rely only on identical integer seeds.

The verification approach will use:

1. deterministic channel matrices;
2. fixed beam codebooks;
3. known reference symbols;
4. manually defined noise-free test cases;
5. stage-by-stage comparison of steering vectors;
6. stage-by-stage comparison of beam-pair scores;
7. tolerance-based comparison of selected beam indices;
8. comparison of final metric scales and trends.

## Planned Verification Tests

| Verification test | Technical purpose | Status |
|---|---|---|
| Steering-vector norm | Verify unit-norm array response | Planned |
| Beamformer norm | Verify equal transmit-power normalization | Planned |
| Broadside response | Verify the expected broadside phase progression | Planned |
| End-fire response | Verify the steering-vector angle convention | Planned |
| Beam-pattern symmetry | Verify expected ULA symmetry | Planned |
| Codebook-size check | Verify the configured number of beams | Planned |
| Beam-angle boundary check | Verify the first and last codebook directions | Planned |
| Beam-pair matrix dimension | Verify \(N_{\mathrm{RX}}\times N_{\mathrm{TX}}\) output dimensions | Planned |
| Noiseless best-beam test | Verify correct selection for a known single-path channel | Planned |
| Angular mismatch test | Verify logical selection between adjacent beams | Planned |
| Noise-sensitivity test | Verify that selection reliability changes logically with SNR | Planned |
| Exhaustive-search reference | Verify that exhaustive search returns the global maximum beam score | Planned |
| MATLAB–Python deterministic comparison | Verify common numerical conventions | Planned |
| Reproducibility test | Verify repeated runs with fixed inputs | Planned |

## Current Development Status

- [x] Project topic defined
- [x] Initial repository created
- [x] Technical scope identified
- [x] Initial mathematical model defined
- [ ] System requirements finalized
- [ ] MATLAB antenna-array model implemented
- [ ] Python antenna-array model implemented
- [ ] Transmit beam codebook implemented
- [ ] Receive beam codebook implemented
- [ ] Directional channel model implemented
- [ ] Exhaustive beam-sweeping algorithm implemented
- [ ] Beam-selection algorithm implemented
- [ ] Monte Carlo simulation implemented
- [ ] Reduced-complexity search implemented
- [ ] Verification tests completed
- [ ] MATLAB–Python cross-verification completed
- [ ] Result figures generated
- [ ] Result tables generated
- [ ] Final technical report completed

This checklist will be updated as the project progresses.

## Planned Repository Structure

```text
01_beam_sweeping_and_beam_selection_simulation/
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
│   ├── matlab_python_comparison/
│   └── verification_logs/
├── docs/
│   ├── technical_notes.md
│   └── technical_report/
└── LICENSE
```

The filenames above describe the planned organization and may be adjusted during development. Existing source filenames will be preserved once implementation begins.

## Software Requirements

### MATLAB

The final MATLAB implementation is expected to require:

- MATLAB;
- optional Phased Array System Toolbox;
- optional Communications Toolbox.

### Python

The Python implementation is expected to use:

- Python 3;
- NumPy;
- SciPy;
- Matplotlib;
- pandas;
- optional pytest for automated verification.

A final dependency file will be added after the implementation becomes stable.

## How to Run

The project is not yet ready for complete execution.

The final commands will be updated after the executable implementation is available.

Planned Python command:

```bash
python python/main_beam_sweeping.py
```

Planned MATLAB command:

```matlab
run("matlab/main_beam_sweeping.m")
```

## Expected Engineering Outcomes

The completed project is expected to demonstrate:

- how directional codebook beams cover an angular search region;
- how transmit and receive beam sweeping creates a beam-pair measurement matrix;
- how the strongest beam pair is selected;
- how beam selection depends on SNR;
- how beam selection depends on antenna-array size;
- how beam selection depends on codebook resolution;
- how angular mismatch produces beam quantization loss;
- why larger codebooks can reduce angular error but increase search overhead;
- how multipath propagation can change the selected beam;
- how blockage can trigger alternative-beam selection;
- how hierarchical search can reduce overhead with a possible loss in accuracy;
- how MATLAB and Python can be used for independent numerical verification.

No final numerical result is claimed while the project remains under development.

## Initial Model Limitations

The first version is expected to use a simplified physical-layer model.

Possible limitations include:

- narrowband beamforming;
- ideal phase shifters;
- perfect antenna calibration;
- no mutual coupling;
- no RF nonlinearities;
- simplified path-loss and channel models;
- ideal timing and carrier synchronization;
- no complete 3GPP beam-management procedure;
- no practical beam-reporting delay;
- no hardware-in-the-loop validation;
- no over-the-air validation.

These limitations will be documented clearly and extended gradually where useful.

## Future Extensions

Possible future extensions include:

- 5G NR synchronization-signal-block beam sweeping;
- CSI-RS-based beam refinement;
- beam reporting;
- beam-failure detection and recovery;
- wideband OFDM beam squint;
- hybrid analog–digital beamforming;
- uniform planar array modeling;
- azimuth and elevation beam search;
- mobility and beam tracking;
- blockage modeling;
- multi-user beam selection;
- interference-aware beam selection;
- machine-learning-assisted beam prediction;
- practical phase-shifter quantization;
- RF impairments;
- antenna-array calibration errors;
- measured channel data;
- ray-tracing channel data;
- hardware-in-the-loop validation;
- over-the-air validation.

## Skills Demonstrated

After completion, this project is expected to demonstrate experience in:

- antenna-array signal processing;
- directional beamforming;
- beam codebook design;
- beam sweeping;
- beam selection;
- wireless channel modeling;
- Monte Carlo simulation;
- numerical verification;
- MATLAB development;
- Python development;
- cross-platform validation;
- RF/PHY performance analysis;
- technical documentation.

## Contribution

This is currently an individual engineering simulation project under active development.

Technical comments and improvement suggestions may be considered after the first executable version is released.

## License

A license will be selected before the source code is publicly released.

Until a `LICENSE` file is added, the project should be treated as **all rights reserved**.

## Author

**Md Moklesur Rahman**  
Wireless/RF/PHY System Engineer  
Finland

## Notice

This README describes the planned scope of an ongoing project.

Features identified as planned have not yet been presented as completed or verified. The README will be updated as implementation, verification, result generation, and documentation progress.
