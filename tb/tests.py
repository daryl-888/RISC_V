"""Directed test programs. Every program ends with 'halt: jal x0, halt'.
Each targets one behavior so a failure points at one piece of the design."""

H = "\nhalt: jal x0, halt\n"

DIRECTED = {
    # ---- ALU, no hazards (nops separate dependent instructions) ----
    "alu_rtype": """
        addi x1, x0, 25
        addi x2, x0, -7
        nop
        nop
        nop
        add  x3, x1, x2
        sub  x4, x1, x2
        and  x5, x1, x2
        or   x6, x1, x2
        xor  x7, x1, x2
        sll  x8, x1, x1
        srl  x9, x2, x1
        sra  x10, x2, x1
        slt  x11, x2, x1
        slt  x12, x1, x2
        sltu x13, x2, x1
        sltu x14, x1, x2
    """ + H,
    "alu_itype": """
        addi x1, x0, -100
        nop
        nop
        nop
        addi  x2, x1, 2047
        slti  x3, x1, -99
        slti  x4, x1, -101
        sltiu x5, x1, -1
        xori  x6, x1, -1
        ori   x7, x1, 0x0F0
        andi  x8, x1, 0x7FF
        slli  x9, x1, 4
        srli  x10, x1, 28
        srai  x11, x1, 2
    """ + H,
    "lui_auipc": """
        lui   x1, 0xDEADB
        auipc x2, 0x1
        auipc x3, 0
        nop
        nop
        nop
        addi  x4, x1, 0x7EF
    """ + H,
    # ---- memory ----
    "load_store_widths": """
        lui  x1, 0x80000
        addi x1, x1, 0x7F6
        addi x2, x0, 64
        nop
        nop
        nop
        sw   x1, 0(x2)
        sh   x1, 8(x2)
        sb   x1, 12(x2)
        nop
        nop
        lw   x3, 0(x2)
        lh   x4, 0(x2)
        lhu  x5, 0(x2)
        lb   x6, 0(x2)
        lbu  x7, 0(x2)
        lh   x8, 2(x2)
        lhu  x9, 2(x2)
        lw   x10, 8(x2)
        lw   x11, 12(x2)
    """ + H,
    # ---- control flow ----
    "branches_taken_and_not": """
        addi x1, x0, 5
        addi x2, x0, -3
        nop
        nop
        nop
        beq  x1, x1, t1
        addi x10, x0, 1
    t1: bne  x1, x1, bad
        blt  x2, x1, t2
        addi x11, x0, 1
    t2: bge  x2, x1, bad
        bltu x1, x2, t3
        addi x12, x0, 1
    t3: bgeu x1, x2, bad
        addi x20, x0, 77
        jal  x0, halt
    bad: addi x21, x0, 99
    """ + H,
    "jal_jalr_link": """
        jal  x1, f
        addi x5, x0, 11
        jal  x0, halt
    f:  addi x6, x0, 22
        jalr x0, 0(x1)
    """ + H,
    "flush_after_taken_branch": """
        addi x1, x0, 1
        nop
        nop
        nop
        beq  x1, x1, skip
        addi x2, x0, 1
        addi x3, x0, 1
        addi x4, x0, 1
    skip: addi x5, x0, 5
    """ + H,
    "loop_sum_1_to_10": """
        addi x1, x0, 10
        addi x2, x0, 0
    loop: add x2, x2, x1
        addi x1, x1, -1
        bne  x1, x0, loop
        sw   x2, 0(x0)
    """ + H,
    # ---- data hazards / forwarding ----
    "fwd_ex_to_ex": """
        addi x1, x0, 3
        addi x2, x1, 4
        add  x3, x2, x1
        sub  x4, x3, x2
    """ + H,
    "fwd_mem_to_ex": """
        addi x1, x0, 9
        nop
        addi x2, x1, 1
        nop
        add  x3, x1, x2
    """ + H,
    "fwd_wb_regfile_bypass": """
        addi x1, x0, 42
        nop
        nop
        addi x2, x1, 0
    """ + H,
    "fwd_priority_newest_wins": """
        addi x1, x0, 1
        addi x1, x0, 2
        addi x1, x0, 3
        addi x2, x1, 0
    """ + H,
    "load_use_stall_rs1": """
        addi x1, x0, 123
        sw   x1, 16(x0)
        lw   x2, 16(x0)
        addi x3, x2, 1
    """ + H,
    "load_use_stall_rs2": """
        addi x1, x0, 50
        sw   x1, 20(x0)
        lw   x2, 20(x0)
        add  x3, x1, x2
    """ + H,
    "store_data_forwarded": """
        addi x1, x0, 77
        sw   x1, 24(x0)
        lw   x2, 24(x0)
        sw   x2, 28(x0)
    """ + H,
    "branch_on_forwarded_value": """
        addi x1, x0, 4
        addi x2, x0, 4
        beq  x1, x2, ok
        addi x3, x0, 1
    ok: addi x4, x0, 1
        lw   x5, 0(x0)
        beq  x5, x0, ok2
        addi x6, x0, 1
    ok2: addi x7, x0, 1
    """ + H,
    "jalr_forwarded_base": """
        addi x1, x0, 16
        jalr x2, 0(x1)
        addi x3, x0, 1
        addi x4, x0, 1
        addi x5, x0, 5
    """ + H,
    "x0_never_written_or_forwarded": """
        addi x0, x0, 5
        add  x1, x0, x0
        addi x0, x0, 7
        nop
        addi x2, x0, 0
    """ + H,
}
