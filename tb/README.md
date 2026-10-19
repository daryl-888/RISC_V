# RISC_V testbench

Drop this `tb/` folder into the root of the `RISC_V` repo (next to `src/`).

```
sudo apt install -y verilator make g++ python3
python3 tb/run_tests.py -v            # 18 directed + 100 random programs
python3 tb/run_tests.py --random 1000 # more random programs
```

## How it works

1. `rv32i.py` assembles each test program and runs it on a simple reference model:
   one instruction at a time, no pipeline. That gives the correct final registers and memory.
2. Verilator compiles `src/riscv_top.v` and `tb_top.sv` into a C++ simulator.
   `sim_main.cpp` resets the core, clocks it, then `tb_top.sv` dumps every register and data-memory byte.
3. `run_tests.py` compares the two. A pipeline is correct only if it ends in exactly the same state
   as the one-instruction-at-a-time model, so any forwarding, stall or flush bug shows up as a mismatch.

`tests.py` holds directed programs, each aimed at one behavior (forwarding paths, load-use stalls,
branch flushes). The random programs use only x1-x6 so nearly every instruction depends on a recent one,
which is what stresses forwarding.

Programs halt with `jal x0, halt` (jump to self). Each test runs in `build/runs/<name>/`, where you can
inspect `instr.txt` and `dut_state.txt`.
