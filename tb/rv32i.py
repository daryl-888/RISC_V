"""Tiny RV32I assembler + reference model (golden ISS).

The testbench idea: run the same program on (1) this simple Python model,
which executes one instruction at a time with no pipeline, and (2) the
Verilog pipeline. If the pipeline is correct, the final registers and
memory must match exactly. Any hazard/forwarding/flush bug shows up as a
mismatch.
"""
import re

M32 = 0xFFFFFFFF
REGS = {f"x{i}": i for i in range(32)}

R_OPS = {  # name: (funct7, funct3)
    "add": (0x00, 0), "sub": (0x20, 0), "sll": (0x00, 1), "slt": (0x00, 2),
    "sltu": (0x00, 3), "xor": (0x00, 4), "srl": (0x00, 5), "sra": (0x20, 5),
    "or": (0x00, 6), "and": (0x00, 7)}
I_OPS = {"addi": 0, "slti": 2, "sltiu": 3, "xori": 4, "ori": 6, "andi": 7}
SH_OPS = {"slli": (0x00, 1), "srli": (0x00, 5), "srai": (0x20, 5)}
LOADS = {"lb": 0, "lh": 1, "lw": 2, "lbu": 4, "lhu": 5}
STORES = {"sb": 0, "sh": 1, "sw": 2}
BRANCHES = {"beq": 0, "bne": 1, "blt": 4, "bge": 5, "bltu": 6, "bgeu": 7}


def _r(s):
    return REGS[s.strip()]


def _imm(s, labels, pc, rel):
    s = s.strip()
    if s in labels:
        return labels[s] - pc if rel else labels[s]
    return int(s, 0)


def assemble(src):
    """Return list of 32-bit words. Syntax: 'op a, b, c', 'lw x1, 4(x2)', 'label:'."""
    lines, labels = [], {}
    for raw in src.splitlines():
        line = raw.split("#")[0].strip()
        while ":" in line:
            lab, line = line.split(":", 1)
            labels[lab.strip()] = 4 * len(lines)
            line = line.strip()
        if line:
            lines.append(line)
    words = []
    for i, line in enumerate(lines):
        pc = 4 * i
        op, _, rest = line.partition(" ")
        a = [x.strip() for x in rest.split(",")] if rest else []
        if op == "nop":
            op, a = "addi", ["x0", "x0", "0"]
        if op in R_OPS:
            f7, f3 = R_OPS[op]
            w = (f7 << 25) | (_r(a[2]) << 20) | (_r(a[1]) << 15) | (f3 << 12) | (_r(a[0]) << 7) | 0x33
        elif op in I_OPS:
            imm = _imm(a[2], labels, pc, False) & 0xFFF
            w = (imm << 20) | (_r(a[1]) << 15) | (I_OPS[op] << 12) | (_r(a[0]) << 7) | 0x13
        elif op in SH_OPS:
            f7, f3 = SH_OPS[op]
            w = (f7 << 25) | ((int(a[2], 0) & 31) << 20) | (_r(a[1]) << 15) | (f3 << 12) | (_r(a[0]) << 7) | 0x13
        elif op in LOADS or op in STORES or op == "jalr":
            m = re.match(r"(.+)\((x\d+)\)", a[1])
            imm, base = int(m.group(1), 0) & 0xFFF, _r(m.group(2))
            if op in LOADS:
                w = (imm << 20) | (base << 15) | (LOADS[op] << 12) | (_r(a[0]) << 7) | 0x03
            elif op == "jalr":
                w = (imm << 20) | (base << 15) | (_r(a[0]) << 7) | 0x67
            else:
                w = ((imm >> 5) << 25) | (_r(a[0]) << 20) | (base << 15) | (STORES[op] << 12) | ((imm & 31) << 7) | 0x23
        elif op in BRANCHES:
            off = _imm(a[2], labels, pc, True) & 0x1FFF
            w = (((off >> 12) & 1) << 31) | (((off >> 5) & 0x3F) << 25) | (_r(a[1]) << 20) | (_r(a[0]) << 15) \
                | (BRANCHES[op] << 12) | (((off >> 1) & 0xF) << 8) | (((off >> 11) & 1) << 7) | 0x63
        elif op == "jal":
            off = _imm(a[1], labels, pc, True) & 0x1FFFFF
            w = (((off >> 20) & 1) << 31) | (((off >> 1) & 0x3FF) << 21) | (((off >> 11) & 1) << 20) \
                | (((off >> 12) & 0xFF) << 12) | (_r(a[0]) << 7) | 0x6F
        elif op in ("lui", "auipc"):
            w = ((int(a[1], 0) & 0xFFFFF) << 12) | (_r(a[0]) << 7) | (0x37 if op == "lui" else 0x17)
        else:
            raise ValueError(f"unknown op: {line}")
        words.append(w)
    return words


def sx(v, bits):
    v &= (1 << bits) - 1
    return v - (1 << bits) if v >> (bits - 1) else v


def simulate(words, mem=None, max_steps=10000):
    """Golden model. Halts on 'jal x0, 0' (jump-to-self). Returns (regs, mem)."""
    x = [0] * 32
    mem = bytearray(mem or bytes(4096))
    pc = 0
    for _ in range(max_steps):
        w = words[pc // 4]
        op, rd, f3 = w & 0x7F, (w >> 7) & 31, (w >> 12) & 7
        rs1, rs2, f7 = (w >> 15) & 31, (w >> 20) & 31, w >> 25
        a, b = x[rs1], x[rs2]
        iimm = sx(w >> 20, 12)
        nxt, res = pc + 4, None
        if op == 0x6F and rd == 0 and w >> 12 == 0:
            break  # jal x0, 0 -> halt
        if op == 0x33:
            res = {0: (a - b) if f7 else (a + b), 1: a << (b & 31),
                   2: int(sx(a, 32) < sx(b, 32)), 3: int(a < b), 4: a ^ b,
                   5: (sx(a, 32) >> (b & 31)) if f7 else (a >> (b & 31)),
                   6: a | b, 7: a & b}[f3]
        elif op == 0x13:
            sh = (w >> 20) & 31
            res = {0: a + iimm, 1: a << sh, 2: int(sx(a, 32) < iimm), 3: int(a < (iimm & M32)),
                   4: a ^ (iimm & M32), 5: (sx(a, 32) >> sh) if f7 & 0x20 else (a >> sh),
                   6: a | (iimm & M32), 7: a & (iimm & M32)}[f3]
        elif op == 0x37:
            res = w & 0xFFFFF000
        elif op == 0x17:
            res = pc + (w & 0xFFFFF000)
        elif op == 0x6F:
            off = sx(((w >> 31) << 20) | (((w >> 12) & 0xFF) << 12) | (((w >> 20) & 1) << 11) | (((w >> 21) & 0x3FF) << 1), 21)
            res, nxt = pc + 4, pc + off
        elif op == 0x67:
            res, nxt = pc + 4, (a + iimm) & ~1
        elif op == 0x63:
            off = sx(((w >> 31) << 12) | (((w >> 7) & 1) << 11) | (((w >> 25) & 0x3F) << 5) | (((w >> 8) & 0xF) << 1), 13)
            sa, sb_ = sx(a, 32), sx(b, 32)
            take = {0: a == b, 1: a != b, 4: sa < sb_, 5: sa >= sb_, 6: a < b, 7: a >= b}[f3]
            if take:
                nxt = pc + off
        elif op == 0x03:
            ad = (a + iimm) & M32
            v = int.from_bytes(mem[ad:ad + 4], "little")
            res = {0: sx(v, 8), 1: sx(v, 16), 2: v, 4: v & 0xFF, 5: v & 0xFFFF}[f3]
        elif op == 0x23:
            ad = (a + sx(((w >> 25) << 5) | ((w >> 7) & 31), 12)) & M32
            n = {0: 1, 1: 2, 2: 4}[f3]
            mem[ad:ad + n] = (b & M32).to_bytes(4, "little")[:n]
        if res is not None and rd:
            x[rd] = res & M32
        pc = nxt & M32
    else:
        raise RuntimeError("program did not halt")
    return x, mem
