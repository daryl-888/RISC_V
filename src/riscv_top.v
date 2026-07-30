`include "pipeline/fetch/IF.v"
`include "pipeline/decode/ID.v"
`include "pipeline/execute/EX.v"
`include "pipeline/memory/MEM.v"
`include "pipeline/writeback/WB.v"
`include "hazard/HAZARD.v"
`include "forward/F.v"

// Leaf modules (ALU, CONTROL, DECODER, REGISTER, INSTRUCTION_MEMORY,
// DATA_MEMORY, BRANCH_JUMP) are pulled in by the stage file that
// instantiates them (IF.v/ID.v/EX.v/MEM.v), not included here.

`default_nettype none
module RISCV_TOP (
    input iClk,
    input iRstN
);

    // Branch/jump redirect, resolved combinationally in EX (2-bubble penalty
    // on a taken branch/jump: the instructions already fetched into IF and ID
    // get flushed the same cycle the branch resolves).
    wire wPcTaken;
    wire [31:0] wPcRedirect;

    // Load-use hazard stall/bubble
    wire wPcStall, wBubble;

    // ---------- IF (owns the IF/ID pipeline register) ----------
    wire [31:0] wIfPc, wIfInstr;

    IF u_if (
        .iClk   (iClk),
        .iRstN  (iRstN),
        .iPcSrc (wPcTaken),
        .iHazard(wPcStall),
        .iFlush (wPcTaken),
        .iPc    (wPcRedirect),
        .oPc    (wIfPc),
        .oInstr (wIfInstr)
    );

    // ---------- ID (owns the register file + ID/EX pipeline register) ----------
    wire [4:0] wIdRs1Addr, wIdRs2Addr; // combinational: instruction currently entering ID

    wire [31:0] wIdExPc, wIdExImm, wIdExRs1Data, wIdExRs2Data;
    wire [2:0]  wIdExFunct3;
    wire [6:0]  wIdExFunct7;
    wire [4:0]  wIdExRdAddr, wIdExRs1AddrReg, wIdExRs2AddrReg;
    wire wIdExLui, wIdExPcSrc, wIdExMemRd, wIdExMemWr, wIdExMemtoReg;
    wire wIdExAluSrc1, wIdExAluSrc2, wIdExRegWrite, wIdExBranch, wIdExJump;
    wire [2:0] wIdExAluOp;

    // Write-back feedback into the register file (same-cycle read-during-write,
    // handled by REGISTER.v's internal bypass)
    wire [31:0] wWbData;
    wire [4:0]  wWbAddr;
    wire wWbEn;

    ID u_id (
        .iClk    (iClk),
        .iRstN   (iRstN),
        .iRegWrEn(wWbEn),
        .iNop    (wBubble),
        .iFlush  (wPcTaken),
        .iRdAddr (wWbAddr),
        .iRdData (wWbData),
        .iPc     (wIfPc),
        .iInstr  (wIfInstr),

        .oRs1Addr(wIdRs1Addr),
        .oRs2Addr(wIdRs2Addr),

        .oPc(wIdExPc), .oImm(wIdExImm), .oFunct3(wIdExFunct3), .oFunct7(wIdExFunct7),
        .oRdAddr(wIdExRdAddr), .oIdRs1Addr(wIdExRs1AddrReg), .oIdRs2Addr(wIdExRs2AddrReg),
        .oRs1Data(wIdExRs1Data), .oRs2Data(wIdExRs2Data),

        .oLui(wIdExLui), .oPcSrc(wIdExPcSrc), .oMemRd(wIdExMemRd), .oMemWr(wIdExMemWr),
        .oAluOp(wIdExAluOp), .oMemtoReg(wIdExMemtoReg), .oAluSrc1(wIdExAluSrc1),
        .oAluSrc2(wIdExAluSrc2), .oRegWrite(wIdExRegWrite), .oBranch(wIdExBranch), .oJump(wIdExJump)
    );

    // ---------- Hazard detection (load-use stall) ----------
    HAZARD u_hazard (
        .iIdExMemRead(wIdExMemRd),
        .iIdExRd     (wIdExRdAddr),
        .iIfIdRs1    (wIdRs1Addr),
        .iIfIdRs2    (wIdRs2Addr),
        .oPcStall    (wPcStall),
        .oBubble     (wBubble)
    );

    // ---------- EX/MEM register outputs (forward-declared: read by F and MEM) ----------
    wire [31:0] wExMemAluResult, wExMemRs2Data;
    wire [4:0]  wExMemRd;
    wire [2:0]  wExMemFunct3;
    wire wExMemMemRd, wExMemMemWr, wExMemMemtoReg, wExMemRegWrite;

    // ---------- Forwarding unit ----------
    wire wRs1Forward, wRs2Forward;
    wire [31:0] wRs1FwdData, wRs2FwdData;

    F u_forward (
        .iFalseRs1  (1'b0),
        .iFalseRs2  (1'b0),
        .iFalseExRd (!wExMemRegWrite),
        // Store-to-load path is redundant with the rs2 forwarding EX already
        // does one cycle earlier (while the store itself is in EX), so it's
        // kept permanently inert here rather than duplicating that check.
        .iFalseStore(1'b1),
        .iFalseLoad (!wWbEn),
        .iRs1Addr   (wIdExRs1AddrReg),
        .iRs2Addr   (wIdExRs2AddrReg),
        .iExRdAddr  (wExMemRd),
        .iExRs2Addr (5'b0),
        .iMemRdAddr (wWbAddr),
        .iExRdData  (wExMemAluResult),
        .iMemRdData (wWbData),
        .oRs1Forward(wRs1Forward),
        .oRs2Forward(wRs2Forward),
        .oMemForward(),
        .oRs1Data   (wRs1FwdData),
        .oRs2Data   (wRs2FwdData),
        .oMemData   ()
    );

    // ---------- EX ----------
    EX u_ex (
        .iClk(iClk), .iRstN(iRstN),
        .iLui(wIdExLui), .iPcSrc(wIdExPcSrc),
        .iAluSrc1(wIdExAluSrc1), .iAluSrc2(wIdExAluSrc2), .iAluOp(wIdExAluOp),
        .iMemRd(wIdExMemRd), .iMemWr(wIdExMemWr), .iMemtoReg(wIdExMemtoReg),
        .iRegWrite(wIdExRegWrite), .iBranch(wIdExBranch), .iJump(wIdExJump),
        .iPc(wIdExPc), .iRs1Data(wIdExRs1Data), .iRs2Data(wIdExRs2Data), .iImm(wIdExImm),
        .iRd(wIdExRdAddr), .iFunct3(wIdExFunct3), .iFunct7(wIdExFunct7),
        .iRs1Forward(wRs1Forward), .iRs2Forward(wRs2Forward),
        .iRs1FwdData(wRs1FwdData), .iRs2FwdData(wRs2FwdData),
        .oPcTaken(wPcTaken), .oPcRedirect(wPcRedirect),
        .oAluResult(wExMemAluResult), .oRs2Data(wExMemRs2Data), .oRd(wExMemRd),
        .oFunct3(wExMemFunct3), .oMemRd(wExMemMemRd), .oMemWr(wExMemMemWr),
        .oMemtoReg(wExMemMemtoReg), .oRegWrite(wExMemRegWrite)
    );

    // ---------- MEM (owns the EX/MEM->MEM/WB register) ----------
    wire [31:0] wMemWbMemData, wMemWbAluResult;
    wire [4:0] wMemWbRd;
    wire wMemWbMemtoReg, wMemWbRegWrite;

    MEM u_mem (
        .iClk(iClk), .iRstN(iRstN),
        .iAluResult(wExMemAluResult), .iRs2Data(wExMemRs2Data), .iRd(wExMemRd),
        .iFunct3(wExMemFunct3), .iMemRd(wExMemMemRd), .iMemWr(wExMemMemWr),
        .iMemtoReg(wExMemMemtoReg), .iRegWrite(wExMemRegWrite),
        .oMemData(wMemWbMemData), .oAluResult(wMemWbAluResult), .oRd(wMemWbRd),
        .oMemtoReg(wMemWbMemtoReg), .oRegWrite(wMemWbRegWrite)
    );

    // ---------- WB ----------
    WB u_wb (
        .iAluResult(wMemWbAluResult), .iMemData(wMemWbMemData), .iRd(wMemWbRd),
        .iMemtoReg(wMemWbMemtoReg), .iRegWrite(wMemWbRegWrite),
        .oRegWrData(wWbData), .oRegWrAddr(wWbAddr), .oRegWrEn(wWbEn)
    );

endmodule
