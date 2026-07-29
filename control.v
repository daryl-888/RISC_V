module CONTROL (
    input [6:0] iOpcode,
    output [8:0] oEx,
    output [4:0] oMem,
    output [2:0] oWb,
    output oFalseLoadUse
);
    localparam LUI =    7'b0110111;
    localparam AUIPC =  7'b0010111;
    localparam REG =    7'b0110011;
    localparam IMM =    7'b0010011;
    localparam JAL =    7'b1101111;
    localparam JALR =   7'b1100111;
    localparam LOAD =   7'b0000011;
    localparam STORE =  7'b0100011;
    localparam BRANCH = 7'b1100011;

    // Hazard
    wire wFalseRs1, wFalseRs2, wFalseExRd, wFalseStore, wFalseLoad;
	wire [1:0] wAluOp;
    wire wLuiSrc, wPcSrc, wAluResultSrc, wAluSrc2, wAuipcSrc;
	wire wBranchJump, wMemRd, wMemWr;
	wire wRegWr, wMemtoReg;

	assign wFalseRs1 = (iOpcode  != REG    &&
                        iOpcode  != IMM    &&
                        iOpcode  != LOAD   &&
                        iOpcode  != STORE  &&
                        iOpcode  != BRANCH);
	assign wFalseRs2 = (iOpcode  != REG    &&
                        iOpcode  != STORE  &&
                        iOpcode  != BRANCH);
	assign wFalseExRd = (iOpcode != REG    &&
                         iOpcode != IMM    &&
                         iOpcode != LUI    &&
                         iOpcode != AUIPC  &&
                         iOpcode != JAL    &&
                         iOpcode != JALR);
	assign wFalseStore = (iOpcode != Store);
	assign wFalseLoad = (iOpcode != LOAD   &&
                         iOpcode != REG    &&
                         iOpcode != IMM    &&
                         iOpcode != LUI    &&
                         iOpcode != AUIPC  &&
                         iOpcode != JAL    &&
                         iOpcode != JALR);
    assign wFalseLoadUse = (iOpcode != Load);

    assign wLuiSrc = (iOpcode == LUI);
    assign wPcSrc = (iOpcode == JALR);
    assign wAluResultSrc = (iOpcode == JAL || iOpcode == JALR || iOpcode == AUIPC);
    assign wAuipcSrc = (iOpcode == AUIPC);
    assign wAluSrc2 = (iOpcode != REG && iOpcode != BRANCH);
    assign wAluOp = (iOpcode == REG || iOpcode == IMM || iOpcode == JAL || iOpcode == JALR || iOpcode == AUIPC)    ? 2'b00 :
                    (iOpcode == LOAD || iOpcode == STORE) ? 2'b01 :
                                                            2'b10;

    assign oEx = {wAuipcSrc, wFalseRs1, wFalseRs2, wLuiSrc, wPcSrc, wAluResultSrc, wAluSrc2, wAluOp};

	assign wBranchJump = (iOpcode == BRANCH || iOpcode == JAL || iOpcode == JALR);
	assign wMemRd = (iOpcode == LOAD);
	assign wMemWr = (iOpcode == STORE);

	assign oMem = {wFalseExRd, wFalseStore, wBranchJump, wMemRd, wMemWr};

	assign wRegWr = (iOpcode != STORE && iOpcode != BRANCH);
	assign wMemtoReg = (iOpcode == LOAD);

	assign oWb = {wFalseLoad, wRegWrite, wMemtoReg};
endmodule
