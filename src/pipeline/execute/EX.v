`timescale 1ns / 1ps

`include "core/ALU_CONTROL.v"
`include "core/ALU.v"
`include "pipeline/execute/BRANCH_JUMP.v"

/*
 * Execute (EX) Stage
 *
 * Purpose:
 * 1. Selects ALU operands, applying forwarding and the AluSrc1/AluSrc2 muxes.
 * 2. Performs the ALU operation.
 * 3. Resolves branch/jump target and taken/not-taken combinationally, so the
 *    result is available the same cycle for flushing IF/ID and redirecting
 *    fetch (this is a "resolve in EX" design: 2 bubbles on a taken branch).
 * 4. Latches the result and control signals for MEM in the EX/MEM register.
 */
module EX (
    input iClk,
    input iRstN,

    // Control from ID/EX register (mirrors CONTROL.v's flat interface)
    input iLui,
    input iPcSrc,
    input iAluSrc1,
    input iAluSrc2,
    input [2:0] iAluOp,
    input iMemRd,
    input iMemWr,
    input iMemtoReg,
    input iRegWrite,
    input iBranch,
    input iJump,

    // Data from ID/EX register
    input [31:0] iPc,
    input [31:0] iRs1Data,
    input [31:0] iRs2Data,
    input [31:0] iImm,
    input [4:0]  iRd,
    input [2:0]  iFunct3,
    input [6:0]  iFunct7,

    // Forwarding unit (F.v): flag + already-priority-resolved data per operand
    // (F.v internally picks EX/MEM over MEM/WB when both match).
    input        iRs1Forward,
    input        iRs2Forward,
    input [31:0] iRs1FwdData,
    input [31:0] iRs2FwdData,

    // Combinational: resolved this cycle, used to flush IF/ID and redirect fetch
    output oPcTaken,
    output [31:0] oPcRedirect,

    // EX/MEM pipeline register
    output reg [31:0] oAluResult,
    output reg [31:0] oRs2Data,
    output reg [4:0]  oRd,
    output reg [2:0]  oFunct3,
    output reg oMemRd,
    output reg oMemWr,
    output reg oMemtoReg,
    output reg oRegWrite
);

    wire [31:0] wAluSrcA, wAluSrcB;
    wire [31:0] wFinalAluInputA, wFinalAluInputB;
    wire [3:0]  wAluCtrl;
    wire [31:0] wAluResult;
    wire        wAluCond;
    wire [31:0] wBranchTarget;

    // 1. Forwarding muxes: pick the register-file operand before the
    // AluSrc1/AluSrc2 muxes decide whether the ALU even uses it (PC/imm
    // override rs1/rs2 for U/J/I/S-type instructions).
    assign wAluSrcA = iRs1Forward ? iRs1FwdData : iRs1Data;
    assign wAluSrcB = iRs2Forward ? iRs2FwdData : iRs2Data;

    // 2. ALU operand selection. Operand B has three cases, matching the
    // original single-cycle datapath: imm (loads/stores/I-type/AUIPC),
    // literal 4 (JAL/JALR link-address = PC+4, signaled by AluSrc1=1 with
    // AluSrc2=0), or forwarded rs2 (R-type/branch compare).
    assign wFinalAluInputA = iAluSrc1 ? iPc  : wAluSrcA;
    assign wFinalAluInputB = iAluSrc2 ? iImm : (iAluSrc1 ? 32'd4 : wAluSrcB);

    // 3. ALU control decode
    ALU_CONTROL alu_control_unit (
        .iAluOp  (iAluOp),
        .iFunct3 (iFunct3),
        .iFunct7 (iFunct7),
        .oAluCtrl(wAluCtrl)
    );

    // 4. Main ALU
    ALU alu_unit (
        .iDataA  (wFinalAluInputA),
        .iDataB  (wFinalAluInputB),
        .iAluCtrl(wAluCtrl),
        .oData   (wAluResult),
        .oBranch (wAluCond)
    );

    // 5. Branch/jump target. JALR bases off (forwarded) rs1; everything
    // else bases off PC, per CONTROL.v's oPcSrc convention.
    BRANCH_JUMP branch_jump (
        .iBranch (iBranch),
        .iJump   (iJump),
        .iCond   (wAluCond),
        .iOffset (iImm),
        .iPc     (iPc),
        .iRs1    (wAluSrcA),
        .iPcSrc  (iPcSrc),
        .oPc     (wBranchTarget)
    );

    assign oPcTaken    = iJump | (iBranch & wAluCond);
    assign oPcRedirect = wBranchTarget;

    // --- Sequential Logic (EX/MEM Pipeline Register) ---
    always @(posedge iClk or negedge iRstN) begin
        if (!iRstN) begin
            oAluResult <= 32'b0;
            oRs2Data   <= 32'b0;
            oRd        <= 5'b0;
            oFunct3    <= 3'b0;
            oMemRd     <= 1'b0;
            oMemWr     <= 1'b0;
            oMemtoReg  <= 1'b0;
            oRegWrite  <= 1'b0;
        end else begin
            oAluResult <= iLui ? iImm : wAluResult; // LUI result is just the immediate
            oRs2Data   <= wAluSrcB; // forwarded value: stores must write up-to-date data
            oRd        <= iRd;
            oFunct3    <= iFunct3;
            oMemRd     <= iMemRd;
            oMemWr     <= iMemWr;
            oMemtoReg  <= iMemtoReg;
            oRegWrite  <= iRegWrite;
        end
    end

endmodule
