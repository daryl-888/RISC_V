module CONTROL (
    input [6:0] iOpcode,
    output oLui,
    output oPcSrc,
    output oMemRd,
    output oMemWr,
    output [2:0] oAluOp,
    output oMemtoReg,
    output oAluSrc1,
    output oAluSrc2,
    output oRegWrite,
    output oBranch,
    output oJump
);

    //Opcodes
    localparam LUI =      7'b0110111;
    localparam AUIPC =    7'b0010111;
    localparam REG_ARTH = 7'b0110011;
    localparam JAL =      7'b1101111;
    localparam JALR =     7'b1100111;
    localparam LOAD =     7'b0000011;
    localparam STORE =    7'b0100011;
    localparam IMM =      7'b0010011;
    localparam BRANCH =   7'b1100011;

    assign oLui      = (iOpcode == LUI);

    // 1 = branch/jump base is the PC; 0 = base is rs1. Only JALR uses rs1.
    // NOT a don't-care for ordinary instructions: BRANCH_JUMP computes
    // next PC = 4 + base every cycle, so the base must be the PC.
    assign oPcSrc    = (iOpcode != JALR);

    assign oMemRd    = (iOpcode == LOAD);
    assign oMemWr    = (iOpcode == STORE);

    // Family code for ALU_CONTROL. Everything not listed falls through
    // to 000 (the "just ADD" family): LOAD, STORE addresses, LUI (result
    // unused), and JAL/JALR/AUIPC which need PC-based adds.
    assign oAluOp    = (iOpcode == IMM)      ? 3'b001 :
                       (iOpcode == STORE)    ? 3'b010 :
                       (iOpcode == REG_ARTH) ? 3'b011 :
                       (iOpcode == BRANCH)   ? 3'b110 :
                       3'b000;

    assign oMemtoReg = (iOpcode == LOAD);

    // ALU port A = PC instead of rs1 (link address / PC-relative math)
    assign oAluSrc1  = (iOpcode == JAL) || (iOpcode == JALR) || (iOpcode == AUIPC);

    // ALU port B = immediate instead of rs2
    assign oAluSrc2  = (iOpcode == LOAD) || (iOpcode == STORE) ||
                       (iOpcode == IMM)  || (iOpcode == AUIPC);

    // Every instruction that produces a value in rd
    assign oRegWrite = (iOpcode == LOAD) || (iOpcode == REG_ARTH) ||
                       (iOpcode == IMM)  || (iOpcode == LUI)      ||
                       (iOpcode == JAL)  || (iOpcode == JALR)     ||
                       (iOpcode == AUIPC);

    assign oBranch   = (iOpcode == BRANCH);
    assign oJump     = (iOpcode == JAL) || (iOpcode == JALR);

endmodule
