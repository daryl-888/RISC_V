module BRANCH_JUMP (
    input iBranch,
    input iJump,
    input iCond,
    input [31:0] iOffset,
    input [31:0] iPc,
    input [31:0] iRs1,
    input iPcSrc,
    output [31:0] oPc
);

	wire wOffset;			// do we branch or jump?
    wire [31:0] wOffsetSrc; // iOffset (from instruction) or PC + 4;
    wire [31:0] wInstrSrc;  // either rs1 or pc

	assign wOffset = iJump | (iBranch & iCond);
	assign wOffsetSrc = (wOffset) ? iOffset : 32'd4; // not-taken must add 4, not iPc: oPc = wOffsetSrc + wInstrSrc, and wInstrSrc is already iPc (iPc here gave oPc = 2*PC)
	assign wInstrSrc = (iPcSrc) ? iPc : iRs1;
	assign oPc = wOffsetSrc + wInstrSrc;
endmodule
