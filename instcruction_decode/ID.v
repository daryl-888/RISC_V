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
    output [4:0] oRs1Addr,
    output [4:0] oRs2Addr,
    output oFalseLoadStoreRs1,
    output oFalseLoadStoreRs2,
    output reg oFalseLoadUse,
    output reg [2:0] oWb,
    output reg [4:0] oMem,
    output reg [8:0] oEx,
    output reg [31:0] oPc,
    output reg [31:0] oImm,
    output reg [2:0] oFunct3,
    output reg [6:0] oFunct7,
    output reg [4:0] oRdAddr,
    output reg [4:0] oIdRs2Addr,
    output reg [4:0] oIdRs1Addr,
    output reg [31:0] oRs1Data,
    output reg [31:0] oRs2Data
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
    wire [8:0] wEx;
    wire [4:0] wMem;
    wire [2:0] wWb;
    wire wFalseLoadUse;

    assign oFalseLoadStoreRs1 = wEx[7];
    assign oFalseLoadStoreRs2 = wEx[6];

    CONTROL control (
        .iOpcode(wOpcode),
        .oEx(wEx),
        .oMem(wMem),
        .oWb(wWb),
        .oFalseLoadUse(wFalseLoadUse)
    );

	// Register File
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
            oWb <= 0;
            oMem <= 0;
            oEx <= 0;
            oPc <= 0;
            oImm <= 0;
            oFunct3 <= 0;
            oFunct7 <= 0;
            oRdAddr <= 0;
            oIdRs2Addr <= 0;
            oIdRs1Addr <= 0;
            oRs1Data <= 0;
            oRs2Data <= 0;
            oFalseLoadUse <= 0;
        end else begin
            if (iNop || iFlush) begin
                oWb <= 0;
                oMem <= 0;
                oEx <= 0;
                oPc <= 0;
                oImm <= 0;
                oFunct3 <= 0;
                oFunct7 <= 0;
                oRdAddr <= 0;
                oIdRs2Addr <= 0;
                oIdRs1Addr <= 0;
                oRs1Data <= 0;
                oRs2Data <= 0;
                oFalseLoadUse <= 0;
            end else begin
                oWb <= wWb;
                oMem <= wMem;
                oEx <= wEx;
                oPc <= iPc;
                oImm <= wImm;
                oFunct3 <= wFunct3;
                oFunct7 <= wFunct7;
                oRdAddr <= wRdAddr;
                oIdRs2Addr <= oRs2Addr;
                oIdRs1Addr <= oRs1Addr;
                oRs1Data <= wRs1Data;
                oRs2Data <= wRs2Data;
                oFalseLoadUse <= wFalseLoadUse;
            end
        end
    end

endmodule
