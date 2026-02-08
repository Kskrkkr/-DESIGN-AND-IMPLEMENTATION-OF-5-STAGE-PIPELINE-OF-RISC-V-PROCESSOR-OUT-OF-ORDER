# -DESIGN-AND-IMPLEMENTATION-OF-5-STAGE-PIPELINE-OF-RISC-V-PROCESSOR-OUT-OF-ORDER
🔹  This project implements a 5-stage pipelined RISC-V processor with out-of-order execution using RTL design. Key features include instruction buffering, register renaming, dynamic issue, hazard handling, and reorder buffer–based commit for precise exceptions.
**
**Overview**

This project implements a 5-stage RISC-V processor with Out-of-Order (OoO) execution to improve instruction-level parallelism (ILP) while ensuring in-order retirement for correctness. The design is written in SystemVerilog and verified using QuestaSim (Siemens EDA).

**Key Features**

5-stage pipelined architecture
Out-of-order execution with in-order commit
Register renaming (RAT + Free List)
Issue Queue / Reservation Station
Reorder Buffer (ROB) for precise state
Basic branch handling and recovery
Load/Store Unit (LSU) and memory interface (partial)

***

**Pipeline Stages**

IF – Instruction Fetch: PC, instruction memory, redirect on branch
ID – Instruction Decode: opcode decode, register indices, immediates
Rename: architectural → physical register mapping
Issue / Execute: operand readiness tracking and OoO issue
WB / Commit: writeback to PRF and in-order retirement via ROB

***

**Major Microarchitectural Blocks**

Register Alias Table (RAT)
Free List
Issue Queue / Reservation Station
Physical Register File (PRF)
Reorder Buffer (ROB)
Branch Unit
Load Store Unit (LSU)
Instruction & Data Memory Interfaces

***

**Verification**

RTL simulation using QuestaSim
Waveform-based functional verification
Verified OoO execution with in-order commit
Branch misprediction recovery observed via flush/redirect

***

**Tools & Technologies**

SystemVerilog – RTL design and verification
QuestaSim (Siemens EDA) – Simulation and debugging
RISC-V RV32 ISA – Target instruction set

***
## 

## Repository Structure

```text
RISC-V-Out-of-Order-Pipeline-Processor/
├── rtl/
│   ├── frontend/        # IF, ID
│   ├── rename_issue/    # RAT, Free List, Issue Queue
│   ├── execute/         # ALU, Branch Unit
│   ├── commit/          # ROB
│   ├── memory/          # LSU, Cache, Memory system
│   └── top/             # Core top module
├── tb/
│   └── tb_core.sv       # Testbench
├── sim/
│   └── run.do           # QuestaSim script
└── README.md

RISC-V-Out-of-Order-Pipeline-Processor/
├── rtl/
│   ├── frontend/        # IF, ID
│   ├── rename_issue/    # RAT, Free List, Issue Queue
│   ├── execute/         # ALU, Branch Unit
│   ├── commit/          # ROB
│   ├── memory/          # LSU, Cache, Memory system
│   └── top/             # Core top module
├── tb/
│   └── tb_core.sv       # Testbench
├── sim/
│   └── run.do           # QuestaSim script
└── README.md


***
```text
(content here)


**How to Run**

Open QuestaSim
Navigate to the project directory
Run:
do sim/run.do
Inspect waveforms for pipeline and OoO behavior

***

**Future Work**

Full RV32I ISA support
Complete LSQ with forwarding
Instruction/Data caches
Multi-issue execution
Branch prediction
FPGA implementation and optimization
