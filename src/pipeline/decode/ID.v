`include "pipeline/decode/DECODER.v"
`include "core/CONTROL.v"
`include "pipeline/decode/REGISTER.v"

module ID (
    input iClk,
    input iRstN,
    input iRegWrEn,
    input iNop,
    input iFlush,
    input [4:0] iRdAddr,
    input [31:0] iRdData,
    input [31:0] iPc,
    input [31:0] iInstr,

    // Combinational decode of the instruction currently entering ID this
    // cycle (i.e. the IF/ID register's contents). Read by the hazard unit.
    output [4:0] oRs1Addr,
    output [4:0] oRs2Addr,

    // ID/EX pipeline register: data
    output reg [31:0] oPc,
    output reg [31:0] oImm,
    output reg [2:0]  oFunct3,
    output reg [6:0]  oFunct7,
    output reg [4:0]  oRdAddr,
    output reg [4:0]  oIdRs1Addr,
    output reg [4:0]  oIdRs2Addr,
    output reg [31:0] oRs1Data,
    output reg [31:0] oRs2Data,

    // ID/EX pipeline register: control (mirrors CONTROL.v's flat interface)
    output reg oLui,
    output reg oPcSrc,
    output reg oMemRd,
    output reg oMemWr,
    output reg [2:0] oAluOp,
    output reg oMemtoReg,
    output reg oAluSrc1,
    output reg oAluSrc2,
    output reg oRegWrite,
    output reg oBranch,
    output reg oJump
);

    // Instruction Decode
    wire [6:0] wOpcode;
    wire [4:0] wRdAddr;
    wire [2:0] wFunct3;
    wire [6:0] wFunct7;
    wire [31:0] wImm;

    DECODER decoder (
        .iInstr(iInstr),
        .oOpcode(wOpcode),
        .oRd(wRdAddr),
        .oRs1(oRs1Addr),
        .oRs2(oRs2Addr),
        .oFunct3(wFunct3),
        .oFunct7(wFunct7),
        .oImm(wImm)
    );

    // Control Unit
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

    // Register File (lives here: read during ID, written during WB)
    wire [31:0] wRs1Data, wRs2Data;

    REGISTER register (
        .iClk(iClk),
        .iRstN(iRstN),
        .iWriteEn(iRegWrEn),
        .iRdAddr(iRdAddr),
        .iRs1Addr(oRs1Addr),
        .iRs2Addr(oRs2Addr),
        .iWriteData(iRdData),
        .oRs1Data(wRs1Data),
        .oRs2Data(wRs2Data)
    );

    always @(posedge iClk or negedge iRstN) begin
        if (!iRstN) begin
            oPc <= 0; oImm <= 0; oFunct3 <= 0; oFunct7 <= 0; oRdAddr <= 0;
            oIdRs1Addr <= 0; oIdRs2Addr <= 0; oRs1Data <= 0; oRs2Data <= 0;
            oLui <= 0; oPcSrc <= 0; oMemRd <= 0; oMemWr <= 0; oAluOp <= 0;
            oMemtoReg <= 0; oAluSrc1 <= 0; oAluSrc2 <= 0; oRegWrite <= 0;
            oBranch <= 0; oJump <= 0;
        end else if (iNop || iFlush) begin
            // Bubble: clear every control signal so this slot is inert in
            // EX/MEM/WB (RegWrite/MemRd/MemWr/Branch/Jump all 0). Data
            // fields are cleared too, purely for clean waveforms.
            oPc <= 0; oImm <= 0; oFunct3 <= 0; oFunct7 <= 0; oRdAddr <= 0;
            oIdRs1Addr <= 0; oIdRs2Addr <= 0; oRs1Data <= 0; oRs2Data <= 0;
            oLui <= 0; oPcSrc <= 0; oMemRd <= 0; oMemWr <= 0; oAluOp <= 0;
            oMemtoReg <= 0; oAluSrc1 <= 0; oAluSrc2 <= 0; oRegWrite <= 0;
            oBranch <= 0; oJump <= 0;
        end else begin
            oPc <= iPc;
            oImm <= wImm;
            oFunct3 <= wFunct3;
            oFunct7 <= wFunct7;
            oRdAddr <= wRdAddr;
            oIdRs1Addr <= oRs1Addr;
            oIdRs2Addr <= oRs2Addr;
            oRs1Data <= wRs1Data;
            oRs2Data <= wRs2Data;
            oLui <= wLui;
            oPcSrc <= wPcSrc;
            oMemRd <= wMemRd;
            oMemWr <= wMemWr;
            oAluOp <= wAluOp;
            oMemtoReg <= wMemtoReg;
            oAluSrc1 <= wAluSrc1;
            oAluSrc2 <= wAluSrc2;
            oRegWrite <= wRegWrite;
            oBranch <= wBranch;
            oJump <= wJump;
        end
    end

endmodule
