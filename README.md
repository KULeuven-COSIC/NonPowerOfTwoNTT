# Hardware Acceleration of the Prime-Factor and Rader NTT

## Overview
This repository contains the hardware design and supporting scripts for an NTT (Number Theoretic Transform) accelerator based on the Prime-Factor and Rader FFT algorothm. It includes Verilog source files, Python scripts for generation and testing, and verification modules.

## Repository Structure
- `design/`: Contains Verilog source files for the NTT accelerator design.
- `scripts/`: Python scripts for various tasks like generating merged permutations, test vectors, and twiddle factor tables. Also includes generated output files like moduli and twiddle factor lookup.
- `verification/`: Testbench file for verifying the design, including test a vector. More test vectors can be generated with scripts/generate_test_vector.py.

### Design Subdirectories
- `mert/parametric-ntt/`: This design makes use of a Montgomery modular multiplier by Mert et al. https://github.com/acmert/parametric-ntt This multiplier was modified to make optimal use of all DSP register stages on the Alveo FPGA platform.
- `vivado_ips/`: Custom IP modules used in the Vivado design suite.

### Script Details
- Python scripts are used for generating necessary components and test data for the NTT design.
- `generated/`: Contains files generated by the scripts, which are used in the design.
- Running these scripts requires an environment where numpy is installed.
