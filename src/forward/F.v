module F (
    input iFalseRs1,			// False
    input iFalseRs2,			//
    input iFalseExRd,			//
    input iFalseStore,			//
    input iFalseLoad,			//
    input [4:0] iRs1Addr,		// register addr
    input [4:0] iRs2Addr,		//
    input [4:0] iExRdAddr,		// register addr from EX
    input [4:0] iExRs2Addr,		//
    input [4:0] iMemRdAddr,		// register addr from Mem
    input [31:0] iExRdData,		//
    input [31:0] iMemRdData,   	//
    output oRs1Forward,			// Forward flag
    output oRs2Forward,			//
    output oMemForward,			//
    output [31:0] oRs1Data,		// forward data
    output [31:0] oRs2Data,		//
    output [31:0] oMemData		//
);
	// ex -> ex
	// mem -> ex
	// mem -> mem

	assign iValidRs1 = !iFalseRs1 && (iRs1Addr != 0);
    assign iValidRs2 = !iFalseRs2 && (iRs2Addr != 0);
    assign iValidExRd = !iFalseExRd && (iExRdAddr != 0);
    assign iValidStore = !iFalseStore && (iExRs2Addr != 0);
    assign iValidLoad = !iFalseLoad && (iMemRdAddr != 0);

	assign oRs1Forward = iValidRs1 && (iValidExRd && (iRs1Addr == iExRdAddr)) || (iValidLoad && (iRs1Addr == iMemRdAddr));
    assign oRs2Forward = iValidRs2 && (iValidExRd && (iRs2Addr == iExRdAddr)) || (iValidLoad && (iRs2Addr == iMemRdAddr));
	assign oMemForward = iValidStore && iValidLoad && (iExRs2Addr == iMemRdAddr);

	assign oRs1Data = (iRs1Addr == iExRdAddr) ? iExRdData : iMemRdData;
	assign oRs2Data = (iRs2Addr == iExRdAddr) ? iExRdData : iMemRdData;
	assign oMemData = iMemRdData;

endmodule
