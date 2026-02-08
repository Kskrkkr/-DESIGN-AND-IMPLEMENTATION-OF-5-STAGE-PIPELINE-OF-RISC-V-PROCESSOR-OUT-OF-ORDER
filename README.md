# DESIGN AND IMPLEMENTATION OF 5-STAGE OUT-OF-ORDER RISC-V PROCESSOR

🔹 This project implements a 5-stage pipelined RISC-V processor with out-of-order execution using RTL design.  
Key features include instruction buffering, register renaming, dynamic issue, hazard handling, and ROB-based commit for precise exceptions.

---

## Overview

This project implements a 5-stage RISC-V processor with Out-of-Order (OoO) execution to improve instruction-level parallelism (ILP) while ensuring in-order retirement for correctness.  
The design is written in **SystemVerilog** and verified using **QuestaSim (Siemens EDA)**.

---

## Key Features

- 5-stage pipelined architecture  
- Out-of-order execution with in-order commit  
- Register renaming (RAT + Free List)  
- Issue Queue / Reservation Station  
- Reorder Buffer (ROB) for precise state  
- Basic branch handling and recovery  
- Load/Store Unit (LSU) and memory interface (partial)

---

## Pipeline Stages

- **IF – Instruction Fetch:** PC, instruction memory, branch redirect  
- **ID – Instruction Decode:** opcode decode, registers, immediates  
- **Rename:** architectural → physical register mapping  
- **Issue / Execute:** operand readiness tracking and OoO issue  
- **WB / Commit:** PRF writeback and in-order retirement via ROB  

---

## Major Microarchitectural Blocks

- Register Alias Table (RAT)  
- Free List  
- Issue Queue / Reservation Station  
- Physical Register File (PRF)  
- Reorder Buffer (ROB)  
- Branch Unit  
- Load Store Unit (LSU)  
- Instruction & Data Memory Interfaces  

---

## Verification

- RTL simulation using **QuestaSim**  
- Waveform-based functional verification  
- Verified OoO execution with in-order commit  
- Branch misprediction recovery via flush/redirect  

---

## Tools & Technologies

- **SystemVerilog** – RTL design and verification  
- **QuestaSim (Siemens EDA)** – Simulation and debugging  
- **RISC-V RV32 ISA** – Target instruction set  

---

## Repository Structure

```text
RISC-V-Out-of-Order-Pipeline-Processor/
├── rtl/
│   ├── frontend/
│   ├── rename_issue/
│   ├── execute/
│   ├── commit/
│   ├── memory/
│   └── top/
├── tb/
├── sim/
└── README.md


## How to Run
Open QuestaSim
Navigate to the project directory
Run:
do sim/run.do
Inspect waveforms for pipeline and OoO behavior
Future Work
Full RV32I ISA support
Complete LSQ with forwarding
Instruction/Data caches
Multi-issue execution
Branch prediction
FPGA implementation and optimization
