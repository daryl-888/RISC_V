// DECODER module definition
module DECODER (
    input [31:0] iInstr, // 32 bit instruction input
    output [6:0] oOpcode, // 7 bit opcode output (all types)
    output [4:0] oRd,     // 5 bit destination register output (R, I, U, J)
    output [4:0] oRs1,    // 5 bit source register (R, I, S, B)
    output [4:0] oRs2,    // 5 bit source register (R, S, B)
    output [2:0] oFunct3, // 3 bit function output (R, I, S, B)
    output [6:0] oFunct7, // 7 bit function output (R)
    output [31:0] oImm    // 32 bit immediate output (I, S, B, U, J)
);
    // oImm:
    //  sign extend
    //  use opcode to determine the immediate bitfields

    assign oOpcode = iInstr[6:0];
    assign oRd = iInstr[11:7];
    assign oFunct3 = iInstr[14:12];
    assign oRs1 = iInstr[19:15];
    assign oRs2 = iInstr[24:20];
    assign oFunct7 = iInstr[31:25];
    // Build immediates with correct replication counts and bit slices so each branch
    // produces a 32-bit value.
    assign oImm = (oOpcode == 7'b0010011 || oOpcode == 7'b0000011 || oOpcode == 7'b1100111) ? {{21{iInstr[31]}}, iInstr[30:20]} : // I-type
                  (oOpcode == 7'b0110111 || oOpcode == 7'b0010111)                          ? {iInstr[31:12], 12'b0} : // U-type
                  (oOpcode == 7'b0100011)                                                   ? {{21{iInstr[31]}}, iInstr[30:25], iInstr[11:7]} : // S-type (20+7+5=32)
                  (oOpcode == 7'b1100011)                                                   ? {{20{iInstr[31]}}, iInstr[7], iInstr[30:25], iInstr[11:8], 1'b0} : // B-type: 20+1+6+4+1 = 32, bit 0 always 0
                  (oOpcode == 7'b1101111)                                                   ? {{12{iInstr[31]}}, iInstr[19:12], iInstr[20], iInstr[30:21], 1'b0} : // J-type: 12+8+1+10+1 = 32, bit 0 always 0
                                                                                              32'b0;
    // oOpcode == 7'b0110011 = 32'b0 break
endmodule
