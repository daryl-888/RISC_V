# RISC-V Processor Repository Structure

## Overview
This repository contains a RISC-V processor implementation organized by pipeline stages and functional units.

## Directory Layout

```
src/
├── core/                    # Core execution units
│   ├── ALU.v               # Arithmetic/Logic Unit
│   ├── ALU_CONTROL.v       # ALU control signal decoder
│   └── CONTROL.v           # Main control unit (opcode decoder)
│
├── pipeline/               # Pipeline stages
│   ├── fetch/
│   │   └── IF.v            # Instruction Fetch stage
│   ├── decode/
│   │   ├── DECODER.v       # Instruction decoder
│   │   ├── ID.v            # Instruction Decode stage
│   │   └── REGISTER.v      # Register file
│   └── execute/
│       └── BRANCH_JUMP.v   # Branch/Jump control logic
│
├── memory/                 # Memory units
│   ├── INSTRUCTION_MEMORY.v  # Read-only instruction memory
│   └── DATA_MEMORY.v         # Read/write data memory
│
├── hazard/                 # Hazard detection
│   └── HAZARD.v           # Hazard detection logic
│
├── forward/                # Forwarding logic
│   └── F.v                # Forwarding unit
│
└── riscv_top.v            # Top-level module
```

## Module Dependencies

The main entry point is `riscv_top.v`, which instantiates:

1. **Fetch Stage** (`IF.v`)
   - Manages program counter
   - Interfaces with instruction memory

2. **Decode Stage** (`DECODER.v`, `ID.v`, `REGISTER.v`)
   - Parses instruction
   - Reads register file
   - Outputs decoded signals to control unit

3. **Control Path** (`CONTROL.v`, `ALU_CONTROL.v`)
   - Generates control signals based on opcode
   - Drives ALU control signals

4. **Execute Stage** (ALU, `BRANCH_JUMP.v`)
   - Performs arithmetic/logic operations
   - Computes branch addresses

5. **Memory Stage** (`DATA_MEMORY.v`)
   - Handles load/store operations

6. **Hazard Detection & Forwarding**
   - Manages data dependencies
   - Implements bypass paths

## File Naming Convention

- Modules: UPPERCASE (e.g., `ALU.v`, `CONTROL.v`)
- Stages: Descriptive names (e.g., `IF.v` for Instruction Fetch)
- Logic blocks: Lowercase initial if multi-word (e.g., `alu_control.v`)

## Adding New Modules

When adding new modules:
1. Place in appropriate pipeline stage directory
2. Update includes in `riscv_top.v` if necessary
3. Maintain consistent naming convention
4. Add module documentation
