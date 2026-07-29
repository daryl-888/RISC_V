`include "core/ALU.v"
`include "core/ALU_CONTROL.v"
`include "core/CONTROL.v"
`include "pipeline/execute/BRANCH_JUMP.v"
`include "pipeline/decode/DECODER.v"
`include "pipeline/decode/REGISTER.v"
`include "pipeline/fetch/IF.v"
`include "memory/INSTRUCTION_MEMORY.v"
`include "memory/DATA_MEMORY.v"
`include "hazard/HAZARD.v"
`include "forward/F.v"

`default_nettype none
module RISCV_TOP (
    input iClk,
    input iRstN
);
    localparam WIDTH = 32;

    // ---------- 1. PC ----------
    reg  [WIDTH-1:0] wPC;
    wire [WIDTH-1:0] wNextPC;

    always @(posedge iClk or negedge iRstN) begin
        if (!iRstN)
            wPC <= 32'b0;
        else
            wPC <= wNextPC;
    end

    // ---------- 2. Fetch ----------
    wire [WIDTH-1:0] wInstr;

    INSTRUCTION_MEMORY instr_mem (
        .iRdAddr (wPC),
        .oInstr  (wInstr)
    );

    // ---------- 3. Decode ----------
    wire [6:0] wOpcode;
    wire [4:0] wRd;
    wire [2:0] wFunct3;
    wire [4:0] wRs1;
    wire [4:0] wRs2;
    wire [6:0] wFunct7;
    wire [WIDTH-1:0] wImm;

    decoder decoder0 (
        .i_instr  (wInstr),
        .o_opcode (wOpcode),
        .o_rd     (wRd),
        .o_funct3 (wFunct3),
        .o_rs1    (wRs1),
        .o_rs2    (wRs2),
        .o_funct7 (wFunct7),
        .o_imm    (wImm)
    );

    // ---------- 4. Control ----------
    wire wLui, wPcSrc, wMemRd, wMemWr, wMemtoReg, wAluSrc1, wAluSrc2, wRegWrite, wBranch, wJump;
    wire [2:0] wAluOp;

    CONTROL control (
        .iOpcode(wOpcode),
        .oLui(wLui),
        .oPcSrc(wPcSrc),
        .oMemRd(wMemRd),
        .oMemWr(wMemWr),
        .oAluOp(wAluOp),
        .oMemtoReg(wMemtoReg),
        .oAluSrc1(wAluSrc1),
        .oAluSrc2(wAluSrc2),
        .oRegWrite(wRegWrite),
        .oBranch(wBranch),
        .oJump(wJump)
    );

    // ---------- 5. Register file ----------
    wire [31:0] wRs1Data, wRs2Data, wRegWriteData;

    regfile regfile0 (
        .i_clk      (iClk),
        .i_rstn     (iRstN),
        .i_wr_en    (wRegWrite),
        .i_rd_addr  (wRd),
        .i_rs1_addr (wRs1),
        .i_rs2_addr (wRs2),
        .i_rd_data  (wRegWriteData),
        .o_rs1_data (wRs1Data),
        .o_rs2_data (wRs2Data)
    );

    // ---------- 6. ALU control ----------
    wire [3:0] wAluCtrl;

    ALU_CONTROL alu_ctrl (
        .iAluOp   (wAluOp),
        .iFunct3  (wFunct3),
        .iFunct7  (wFunct7),
        .oAluCtrl (wAluCtrl)
    );

    // ---------- 7. ALU + operand muxes ----------
    wire [31:0] wAluResult;
    wire wAluBranch;
    wire [31:0] wAluData1, wAluData2;

    assign wAluData1 = wAluSrc1 ? wPC : wRs1Data;

    assign wAluData2 = wAluSrc2 ? wImm :
                       wAluSrc1 ? 32'd4 : wRs2Data;

    ALU alu (
        .iDataA   (wAluData1),
        .iDataB   (wAluData2),
        .iAluCtrl (wAluCtrl),
        .oData    (wAluResult),
        .oBranch  (wAluBranch)
    );

    // ---------- 8. Data memory ----------
    wire [31:0] wReadData;

    DATA_MEMORY data_mem (
        .iClk       (iClk),
        .iAddress   (wAluResult),
        .iWriteData (wRs2Data),
        .iFunct3    (wFunct3),
        .iMemWrite  (wMemWr),
        .iMemRead   (wMemRd),
        .oReadData  (wReadData)
    );

    // ---------- 9. Writeback ----------
    wire [31:0] wMemToRegData;

    assign wMemToRegData = wMemtoReg ? wReadData : wAluResult;
    assign wRegWriteData = wLui ? wImm : wMemToRegData;

    // ---------- 10. Next PC ----------
    BRANCH_JUMP branch_jump (
        .iBranch (wBranch),
        .iJump   (wJump),
        .iCond   (wAluBranch),
        .iOffset (wImm),
        .iPc     (wPC),
        .iRs1    (wRs1Data),
        .iPcSrc  (wPcSrc),
        .oPc     (wNextPC)
    );

endmodule
