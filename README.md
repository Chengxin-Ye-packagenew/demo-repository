# Welcome to chengxin ye's pacakage about the trajectory reconstruction framework
# Physics-Informed Multi-Lane Trajectory Reconstruction (PIMTR) Framework

[cite_start]This repository provides the implementation of a physics-informed microscopic-macroscopic fusion framework designed for high-resolution vehicle trajectory reconstruction and emission characterization under sparse sensing environments[cite: 37, 42].

## 1. Research Motivation and Optimization Goals
[cite_start]Reliable trajectory reconstruction is a fundamental imperative for advancing Intelligent Transportation Systems (ITS) and high-fidelity emission modeling[cite: 70]. [cite_start]However, urban sensing is often constrained by low detector density and insufficient floating-vehicle penetration, leading to fragmented data[cite: 71, 72]. To address these limitations, this framework focuses on three primary optimization objectives:
* [cite_start]**Cross-Scale Consistency**: Synchronizing macroscopic traffic-wave propagation with microscopic vehicle dynamics to prevent state misalignment[cite: 38, 104].
* [cite_start]**Kinematic Physical Rationality**: Enforcing rigorous vehicle dynamics constraints (acceleration and jerk boundaries) to eliminate unrealistic kinematic spikes common in traditional models[cite: 73, 258].
* [cite_start]**Spatiotemporal Continuity**: Utilizing multi-lane fusion and lane-change localization modules to ensure lateral coherence and mitigate trajectory fragmentation[cite: 104, 267].

## 2. Methodology and Repository Structure
[cite_start]The codebase is primarily implemented in MATLAB and is architecturally structured around the core modules of the proposed framework[cite: 290]:

### 2.1 Pre-processing (`Pre Process`)
* **Functionality**: Initial data cleansing and standardization.
* [cite_start]**Mechanism**: This module processes raw data from dual fixed sensors and probe vehicle (PV) trajectories, performing preliminary kinematic checks to filter out noise and prepare formatted inputs for subsequent modeling[cite: 312, 567].

### 2.2 Macroscopic Module (`Macro adaptive smoothing`)
* [cite_start]**Core Algorithm**: Adaptive Dual-filter Interpolation[cite: 329].
* [cite_start]**Mechanism**: It constructs a continuous spatiotemporal velocity reference surface by integrating anisotropic kernels skewed along principal axes[cite: 379, 402]. [cite_start]By dynamically adjusting propagation speeds for free-flow and congested regimes, it establishes a global traffic state context to anchor microscopic reconstruction[cite: 246, 331].

### 2.3 Microscopic Module (`Micro HMM` & `Micro DTW`)
This module integrates vehicle dynamics with stochastic behavior through two sub-components:
* [cite_start]**Micro HMM**: Implements a stochastic acceleration Hidden Markov Model constrained by dynamic envelopes[cite: 483, 486]. [cite_start]It categorizes driving states into acceleration, deceleration, and cruising to ensure physically feasible motion states[cite: 257, 511].
* [cite_start]**Micro DTW**: Implements a bidirectional car-following model driven by Dynamic Time Warping[cite: 670]. [cite_start]It leverages the theoretical linkage between the DTW alignment slope and traffic wave propagation speeds to embed macroscopic wave constraints into microscopic trajectory evolution[cite: 671, 821].

### 2.4 Fusion Module (`Fused`)
* [cite_start]**Core Algorithm**: Non-linear Time-Varying Weight Trajectory Fusion[cite: 1034].
* [cite_start]**Mechanism**: For non-probe vehicles and lane-changing maneuvers, this module identifies feasible lane-change regions and virtual monitoring points[cite: 1118, 1120]. [cite_start]It utilizes dynamic programming to determine optimal fusion weights, ensuring the final reconstructed paths are both kinematically plausible and macroscopically consistent[cite: 1078, 1091].

### 2.5 Emission Evaluation (`Emission Evaluate`)
* [cite_start]**Functionality**: High-fidelity spatiotemporal emission estimation[cite: 41, 1380].
* [cite_start]**Mechanism**: Reconstructed trajectories are integrated with the Motor Vehicle Emission Simulator (MOVES) to quantify pollutants such as NOx[cite: 1250, 1380]. [cite_start]The framework achieves high precision in hotspot identification, reaching a 92.23% IoU in validating the sensitivity of emission segmentation[cite: 41, 1295].

## 3. Performance Validation
[cite_start]Validated on NGSIM and MAGIC datasets, the framework significantly outperforms traditional microscopic, macroscopic, and hybrid benchmarks[cite: 40, 1296]:
* [cite_start]**Reconstruction Accuracy**: Reduces Mean Absolute Error (MAE) by up to 75% and Root Mean Square Error (RMSE) by 60% compared to microscopic-based methods[cite: 1318, 1319].
* [cite_start]**Hotspot Identification**: Demonstrates superior efficacy in localized pollution source identification by balancing high detection sensitivity with precision[cite: 1387, 1392].



