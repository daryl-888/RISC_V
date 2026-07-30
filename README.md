# RISC-V 5-Stage Pipeline

A RISC-V CPU written from scratch in Verilog, going from a single-cycle design to a proper 5-stage pipeline (IF/ID/EX/MEM/WB) with hazard detection and forwarding. Built as a learning project, target hardware is a Digilent Basys 3 (Artix-7).

Supports the base RV32I integer instructions: LUI, AUIPC, JAL, JALR, loads/stores, the immediate and register ALU ops, and branches. No FENCE, ECALL/EBREAK, or CSR instructions.

## Status

The pipeline is wired end to end and the control/hazard/forwarding logic has been traced by hand for the standard cases (load-use stalls, back-to-back ALU dependencies, taken branches flushing IF/ID). None of it has been run through a simulator yet, so treat it as "should work on paper" rather than "verified." No testbench exists in the repo right now — that's the next thing to add before touching real hardware.

## Layout

```
src/
  core/            ALU, ALU control decode, main control unit
  memory/          instruction memory, data memory
  pipeline/
    fetch/         IF stage (owns the PC and IF/ID register)
    decode/        ID stage (register file lives here, decodes + reads regs)
    execute/       EX stage (ALU op, branch/jump resolution)
    memory/        MEM stage (load/store)
    writeback/     WB stage (write-back mux)
  hazard/          load-use hazard detection
  forward/         EX/MEM and MEM/WB forwarding unit
  riscv_top.v      top-level, wires all the stages together
```

Each pipeline register (IF/ID, ID/EX, EX/MEM, MEM/WB) lives inside the stage module that produces it, not in the top-level file. Control signals are passed as separate named wires rather than packed into bit vectors — easier to read in a waveform later.

## Branch handling

Branches and jumps resolve in EX, not earlier. That means every taken branch costs 2 bubbles (the instructions already sitting in IF and ID get flushed). No branch prediction, not planned for now.

## Why it's structured this way

This started as a single-cycle datapath (still readable in the git history) and got rebuilt stage by stage. Some of the module boundaries are a bit more granular than strictly necessary — that's intentional, it's easier to reason about one stage at a time when you're the one debugging it later.

## TODO

- Testbench + simulation (iverilog most likely)
- Hand-assembled test programs to exercise hazards/branches
- Synthesis + timing check on the Basys 3
- CSR / ECALL support if it ends up being needed
