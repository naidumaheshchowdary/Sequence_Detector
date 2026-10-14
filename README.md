# SystemVerilog Sequence Detectors (0000_0100_1000)

[![Language](https://img.shields.io/badge/Language-SystemVerilog-orange.svg)]()
[![FSM Type](https://img.shields.io/badge/Architecture-Moore%20%2F%20Mealy-blue.svg)]()
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

A complete set of SystemVerilog Finite State Machine (FSM) implementations for detecting the 13-bit sequence **`0000010010000`**. The repository covers all 4 standard FSM variations:

- **Moore Non-Overlapping**
- **Moore Overlapping**
- **Mealy Non-Overlapping**
- **Mealy Overlapping**

---

## 📌 Table of Contents
- [Overview](#-overview)
- [FSM Architecture & Comparison](#-fsm-architecture--comparison)
- [Repository Structure](#-repository-structure)
- [State Machine Transitions](#-state-machine-transitions)
- [Getting Started & Simulation](#-getting-started--simulation)
- [License](#-license)

---

## 🔍 Overview

This project implements robust, synthesizable 2-process FSMs in SystemVerilog to detect the 13-bit serial bitstream **`0000010010000`**. 

Target sequence breakdown:
- **`00000`** (5 leading zeros, handled with a self-loop on $S_5$)
- **`1`** (1 bit)
- **`00`** (2 bits)
- **`1`** (1 bit)
- **`0000`** (4 trailing zeros)

---

## ⚡ FSM Architecture & Comparison

| Module Name | FSM Style | Overlap Mode | Total States | Detection Trigger Point |
| :--- | :--- | :--- | :---: | :--- |
| `Moore_Nonover_seq` | **Moore** | Non-Overlapping | 13 ($S_0 \dots S_{12}$) | Asserts `Out` on state $S_{12}$ for 1 full clock cycle. Consumes the 13th bit to evaluate $S_0/S_1$. |
| `Moore_Over_seq` | **Moore** | Overlapping | 13 ($S_0 \dots S_{12}$) | Asserts `Out` on state $S_{12}$. On $A=0$, transitions to $S_4$ (reusing trailing `0000`). |
| `Mealy_Nonover_seq` | **Mealy** | Non-Overlapping | 12 ($S_0 \dots S_{11}$) | Asserts `Out` combinationally when $CS=S_{11}$ and $A=0$. Restarts search without reusing bits. |
| `Mealy_Over_seq` | **Mealy** | Overlapping | 12 ($S_0 \dots S_{11}$) | Asserts `Out` combinationally when $CS=S_{11}$ and $A=0$. On $A=0$, transitions to $S_4$ to preserve overlap. |

---

## 📁 Repository Structure

```text
.
├── Design/
│   ├── Mealy_Nonover_seq.sv   # Mealy Non-Overlapping FSM
│   ├── Mealy_Over_seq.sv      # Mealy Overlapping FSM
│   ├── Moore_Nonover_seq.sv   # Moore Non-Overlapping FSM
│   └── Moore_Over_seq.sv      # Moore Overlapping FSM
├── Testbench/                 # (Optional) Place your simulation testbenches here
└── README.md




