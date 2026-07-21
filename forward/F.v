module F (
    input iFalseRs1,
    input iFalseRs2,
    input iFalseExRd,
    input iFalseStore,
    input iFalseLoad,
    input [4:0] iRs1Addr,
    input [4:0] iRs2Addr,
    input [4:0] iExRdAddr,
    input [4:0] iExRs2Addr,
    input [4:0] iMemRdAddr,
    input [31:0] iExRdData,
    input [31:0] iMemRdData,
    output oRs1Forward,
    output oRs2Forward,
    output oMemForward,
    output [31:0] oRs1Data,
    output [31:0] oRs2Data,
    output [31:0] oMemData
);
	// ex -> ex forwarding (output of ex stage to rs1 or rs2) (read after write)
	// mem -> ex forwarding (output of mem stage to rs1 or rs2) (read after load)
	// wb -> mem forwarding (output of wb stage to mem)	(load after store)

    wire iValidRs1, iValidRs2, iValidExRd, iValidStore, iValidLoad;

    assign iValidRs1 = // valid forwarding for rs_
    assign iValidRs2 = //
    assign iValidExRd = //
    assign iValidStore = // valid forwarding for load / store
    assign iValidLoad =  //

    assign oRs1Forward = // Do we actually forward to rs1
    assign oRs2Forward = // to rs2
    assign oMemForward = // to mem

    assign oRs1Data = // forwarded rs1 data
    assign oRs2Data = // forwarded rs2 data
    assign oMemData = // forwarded mem data
endmodule
