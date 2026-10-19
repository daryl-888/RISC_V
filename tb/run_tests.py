#!/usr/bin/env python3
"""Build the Verilator model once, run every test, compare against the Python
reference model. Usage: python3 tb/run_tests.py [--random N] [--seed S] [-v]"""
import argparse, os, random, shutil, subprocess, sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
sys.path.insert(0, HERE)
from rv32i import assemble, simulate  # noqa: E402
from tests import DIRECTED, H  # noqa: E402

BUILD = os.path.join(ROOT, "build")
SIM = os.path.join(BUILD, "obj_dir", "Vtb_top")


def build():
    """Verilate to C++, then compile with make. Works on Verilator 4.x and 5.x."""
    os.makedirs(BUILD, exist_ok=True)
    mdir = os.path.join(BUILD, "obj_dir")
    cmd = ["verilator", "--cc", "--exe", "-Wno-fatal", "-Wno-lint", "-Wno-style",
           "-I" + os.path.join(ROOT, "src"), "--top-module", "tb_top", "--Mdir", mdir,
           os.path.join(ROOT, "src", "riscv_top.v"), os.path.join(HERE, "tb_top.sv"),
           os.path.join(HERE, "sim_main.cpp")]
    for c in (cmd, ["make", "-s", "-j", str(os.cpu_count() or 2), "-C", mdir, "-f", "Vtb_top.mk"]):
        r = subprocess.run(c, capture_output=True, text=True)
        if r.returncode:
            print(r.stdout[-3000:], r.stderr[-3000:])
            sys.exit("Verilator build failed")


def random_program(rng, n=40):
    """Random ALU + load/store mix on x1..x6 so almost every instruction depends
    on a recent one (stresses forwarding and stalls). Memory stays in 0..252."""
    lines = [f"addi x{r}, x0, {rng.randint(-200, 200)}" for r in range(1, 7)]
    lines.append("addi x7, x0, 0")  # x7 = memory base, always 0
    regs = [f"x{r}" for r in range(1, 7)]
    for _ in range(n):
        k = rng.random()
        d, a, b = rng.choice(regs), rng.choice(regs), rng.choice(regs)
        if k < 0.45:
            op = rng.choice(["add", "sub", "and", "or", "xor", "slt", "sltu", "sll", "srl", "sra"])
            lines.append(f"{op} {d}, {a}, {b}")
        elif k < 0.7:
            op = rng.choice(["addi", "xori", "ori", "andi", "slti", "sltiu"])
            lines.append(f"{op} {d}, {a}, {rng.randint(-2048, 2047)}")
        elif k < 0.85:
            lines.append(f"sw {a}, {4 * rng.randint(0, 63)}(x7)")
        else:
            lines.append(f"lw {d}, {4 * rng.randint(0, 63)}(x7)")
    return "\n".join(lines) + H


def run_one(name, src, verbose):
    words = assemble(src)
    exp_regs, exp_mem = simulate(words)
    d = os.path.join(BUILD, "runs", name)
    shutil.rmtree(d, ignore_errors=True)
    os.makedirs(d)
    with open(os.path.join(d, "instr.txt"), "w") as f:
        for w in words:
            for k in range(4):
                f.write(f"{(w >> (8 * k)) & 0xFF:02x}\n")
    with open(os.path.join(d, "data.txt"), "w") as f:
        f.write("00\n" * 4096)
    cycles = 4 * len(words) * 12 + 50  # generous: loops + stalls + flushes
    subprocess.run([SIM, f"+cycles={cycles}"], cwd=d, capture_output=True, text=True, check=True)
    got_regs, got_mem = [0] * 32, bytearray(4096)
    for line in open(os.path.join(d, "dut_state.txt")):
        t, i, v = line.split()
        if t == "R":
            got_regs[int(i)] = int(v, 16) if "x" not in v.lower() else -1
        else:
            got_mem[int(i)] = int(v, 16) if "x" not in v.lower() else 0
    errs = [f"x{i}: expected {exp_regs[i]:08x}, got {got_regs[i]:08x}"
            for i in range(32) if exp_regs[i] != got_regs[i]]
    errs += [f"mem[{i}]: expected {exp_mem[i]:02x}, got {got_mem[i]:02x}"
             for i in range(4096) if exp_mem[i] != got_mem[i]]
    print(f"{'PASS' if not errs else 'FAIL'}  {name}")
    if errs and verbose:
        for e in errs[:8]:
            print("        " + e)
    return not errs


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--random", type=int, default=100)
    ap.add_argument("--seed", type=int, default=1)
    ap.add_argument("-v", action="store_true")
    a = ap.parse_args()
    build()
    results = {n: run_one(n, s, a.v) for n, s in DIRECTED.items()}
    rng = random.Random(a.seed)
    rand_ok = sum(run_one(f"random_{i:03d}", random_program(rng), a.v) for i in range(a.random))
    d_ok = sum(results.values())
    print(f"\nDirected: {d_ok}/{len(results)} passing")
    print(f"Random:   {rand_ok}/{a.random} passing (seed {a.seed})")
    sys.exit(0 if d_ok == len(results) and rand_ok == a.random else 1)


if __name__ == "__main__":
    main()
