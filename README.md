# Welcome to chengxin ye's pacakage about the trajectory reconstruction framework
# Physics-Informed Multi-Lane Trajectory Reconstruction (PIMTR) Framework

This repository provides the implementation of a physics-informed microscopic-macroscopic fusion framework designed for high-resolution vehicle trajectory reconstruction and emission characterization under sparse sensing environments.

## 1. Research Motivation and Optimization Goals
Reliable trajectory reconstruction is a fundamental imperative for advancing Intelligent Transportation Systems (ITS) and high-fidelity emission modeling. However, urban sensing is often constrained by low detector density and insufficient floating-vehicle penetration, leading to fragmented data. To address these limitations, this framework focuses on three primary optimization objectives:
* **Cross-Scale Consistency**: Synchronizing macroscopic traffic-wave propagation with microscopic vehicle dynamics to prevent state misalignment.
* **Kinematic Physical Rationality**: Enforcing rigorous vehicle dynamics constraints (acceleration and jerk boundaries) to eliminate unrealistic kinematic spikes common in traditional models.
* **Spatiotemporal Continuity**: Utilizing multi-lane fusion and lane-change localization modules to ensure lateral coherence and mitigate trajectory fragmentation.

## 2. Methodology and Repository Structure
The codebase is primarily implemented in MATLAB and is architecturally structured around the core modules of the proposed framework:

### 2.1 Pre-processing (`Pre Process`)
* **Functionality**: Initial data cleansing and standardization.
***Mechanism**: This module processes raw data from dual fixed sensors and probe vehicle (PV) trajectories, performing preliminary kinematic checks to filter out noise and prepare formatted inputs for subsequent modeling.

### 2.2 Macroscopic Module (`Macro adaptive smoothing`)
* **Core Algorithm**: Adaptive Dual-filter Interpolation.
* **Mechanism**: It constructs a continuous spatiotemporal velocity reference surface by integrating anisotropic kernels skewed along principal axes. By dynamically adjusting propagation speeds for free-flow and congested regimes, it establishes a global traffic state context to anchor microscopic reconstruction.

### 2.3 Microscopic Module (`Micro HMM` & `Micro DTW`)
This module integrates vehicle dynamics with stochastic behavior through two sub-components:
***Micro HMM**: Implements a stochastic acceleration Hidden Markov Model constrained by dynamic envelopes. It categorizes driving states into acceleration, deceleration, and cruising to ensure physically feasible motion states.
* **Micro DTW**: Implements a bidirectional car-following model driven by Dynamic Time Warping. It leverages the theoretical linkage between the DTW alignment slope and traffic wave propagation speeds to embed macroscopic wave constraints into microscopic trajectory evolution.

### 2.4 Fusion Module (`Fused`)
**Core Algorithm**: Non-linear Time-Varying Weight Trajectory Fusion.
* **Mechanism**: For non-probe vehicles and lane-changing maneuvers, this module identifies feasible lane-change regions and virtual monitoring points. It utilizes dynamic programming to determine optimal fusion weights, ensuring the final reconstructed paths are both kinematically plausible and macroscopically consistent.

### 2.5 Emission Evaluation (`Emission Evaluate`)
* **Functionality**: High-fidelity spatiotemporal emission estimation.
* **Mechanism**: Reconstructed trajectories are integrated with the Motor Vehicle Emission Simulator (MOVES) to quantify pollutants such as NOx. The framework achieves high precision in hotspot identification, reaching a 92.23% IoU in validating the sensitivity of emission segmentation.

## 3. Performance Validation
Validated on NGSIM and MAGIC datasets, the framework significantly outperforms traditional microscopic, macroscopic, and hybrid benchmarks:
* **Reconstruction Accuracy**: Reduces Mean Absolute Error (MAE) by up to 75% and Root Mean Square Error (RMSE) by 60% compared to microscopic-based methods.
* **Hotspot Identification**: Demonstrates superior efficacy in localized pollution source identification by balancing high detection sensitivity with precision.

The basic framework process visulization can be seen in demo-repository/Process visulization.gif.



