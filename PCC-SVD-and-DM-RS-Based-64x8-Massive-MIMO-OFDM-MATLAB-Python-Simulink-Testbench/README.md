# Design, Modeling, and Verification of a PCC-SVD and DM-RS-Based 64 × 8 Massive MIMO-OFDM MATLAB–Python–Simulink Testbench

**Author:** Md Moklesur Rahman  
**Affiliation:** Independent Researcher, Finland  
**Technical area:** 5G NR-oriented physical-layer simulation, Massive MIMO-OFDM, SVD precoding, effective-channel estimation, MATLAB, Python, and Simulink  
**Manuscript status:** Prepared for journal submission.

---
# PCC-SVD and DM-RS-Based 64 × 8 Massive MIMO-OFDM MATLAB–Python–Simulink Testbench

## Project Status

This project is currently being prepared for journal submission.

The complete manuscript, source code, Simulink model, architecture diagrams, simulation results, verification data, and reproducibility package are not publicly available at this stage.

## Project Scope

This work investigates a 64 × 8 Massive MIMO-OFDM physical-layer testbench implemented using MATLAB, Python, and Simulink. The study considers SVD-based precoding, DM-RS-based effective-channel estimation, linear equalization, and cross-platform verification.

Only this brief project description is provided before publication.

## Planned Public Release

After the publication process is complete and the applicable journal policy permits public release, this repository may be updated with:

- the permitted manuscript version;
- MATLAB implementation;
- Python implementation;
- Simulink testbench;
- simulation configuration;
- result figures and tables;
- verification scripts and logs;
- reproducibility instructions.

## Availability

Project materials are currently private to protect the journal-submission and peer-review process.

---

## Performance Metrics

| Metric | Purpose |
|---|---|
| BER | Hard-decision payload bit error rate |
| BER confidence interval | Exact statistical uncertainty from raw error and bit counts |
| RMS EVM | Equalized-symbol distortion before hard decisions |
| Effective-channel NMSE | Error between \(\widehat{\mathbf{G}}[k]\) and \(\mathbf{G}[k]\) |
| Exact effective-channel capacity | Information-theoretic spatial-gain reference |
| \(\eta_{\mathrm{PR}}\) | Noise-free pilot-reconstruction incompatibility |
| \(\eta_{\mathrm{SC}}\) | Normalized dominant-subspace capture |
| \(\eta_{\mathrm{EC}}\) | End-to-end equalizer consistency error |
| Selected bundle | Frame-level PCC-SVD update granularity |
| Runtime | Candidate-construction and selection complexity |

No single metric is sufficient. Capacity and \(\eta_{\mathrm{SC}}\) characterize the spatial opportunity created by the precoder, while BER, EVM, receiver NMSE, and \(\eta_{\mathrm{EC}}\) show how much of that opportunity survives practical estimation and detection.

---

## MATLAB–Python Algorithm Mapping

| Technical operation | MATLAB stage | Python stage |
|---|---|---|
| Layer mapping and digital precoding | `buildFrame`, `applyPrecoder` | `build_frame`, `apply_precoder` |
| TDL physical channel | `generateTdlChannel` | `generate_tdl_channel` |
| Covariance-SVD candidate bank | `covarianceSvdCandidate` | `covariance_svd_candidate` |
| Unitary Procrustes alignment | `alignSvdBases` | `align_svd_bases` |
| PCC-SVD selection | `precoderChannelEstimatorCompatibilitySvd` | `precoder_channel_estimator_compatibility_svd` |
| Effective-channel formation | `trueEffectiveChannel` | `true_effective_channel` |
| DM-RS LS estimation | `estimateEffectiveChannelLs` | `estimate_effective_channel_ls` |
| ZF / gain-corrected MMSE | `equalizeLayers` | `equalize_layers` |
| Metrics and confidence reporting | Metric functions and CSV writers | Metric functions and adaptive publication driver |

MATLAB and NumPy use different random-number generators. Therefore, independent Monte Carlo campaigns are compared through matched equations, dimensions, configuration, metric scale, and scenario ordering rather than by claiming sample-identical random output. Deterministic shared vectors are used for stage-by-stage numerical convention checks.

---

## Simulink Testbench


The Simulink model is an executable orchestration testbench. A run-trigger signal activates a Level-2 MATLAB S-function that calls the verified MATLAB numerical engine.

The output vector reports:

- execution status;
- passed verification-check count;
- total verification-check count;
- BER;
- effective-channel NMSE;
- selected candidate bundle.

The model supports:

- **testbench mode:** nine verification checks plus a finite 10 dB PCC-SVD smoke test;
- **analysis mode:** the complete MATLAB campaign and final PCC-SVD outputs.

The lower workflow region documents the end-to-end sequence. It is not presented as a separate native block-by-block implementation of every \(64\times8\) matrix operation.

---

## Numerical Verification

All nine common MATLAB and Python verification gates passed.

| Verification gate | Technical purpose | Status |
|---|---|---|
| Wideband semi-unitarity | Verify \(\mathbf{W}^{H}\mathbf{W}=\mathbf{I}_{L}\) and equal transmit-power normalization | PASS |
| Aligned per-subcarrier semi-unitarity | Verify basis alignment preserves column orthonormality | PASS |
| PCC-SVD semi-unitarity | Verify the selected frequency-indexed precoder remains semi-unitary | PASS |
| Effective-channel dimensions | Verify the expected \(K\times N_R\times L\) representation | PASS |
| 16-QAM round trip | Verify mapper/demapper bit and symbol ordering | PASS |
| Noiseless flat-channel LS | Verify exact pilot division and interpolation recovery | PASS |
| Noiseless end-to-end recovery | Verify mapping, equalization, ordering, and demapping | PASS |
| Alignment reduces pilot error | Verify Procrustes alignment reduces \(\eta_{\mathrm{PR}}\) | PASS |
| PCC constraint or fallback | Verify feasible selection or deterministic fallback | PASS |

Passing these gates does not prove global optimality, but failure of any gate invalidates the corresponding numerical campaign.

---

---

## Contact

**Md Moklesur Rahman**  
Independent Researcher, Finland  
Email: `moklesur.eee@gmail.com`  
GitHub: `dipucwc`
