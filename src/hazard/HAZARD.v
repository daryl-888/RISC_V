module H (
	input iFalseRs1,		// False hazards
    input iFalseRs2,		//
    input iFalseLoadStore,  //
    input iFlush,			// Incorrect Branch
    input [4:0] iRs1Addr,	// Registers Addresses
    input [4:0] iRs2Addr,   //
    input [4:0] iExRdAddr,  // Execute stage read address
    output oHazard,			// Hazard
    output oFlush			// Flush
);

	wire wRs1Valid, wRs2Valid, wLoadStoreValid;
	wire wRs1LoadStore, wRs2LoadStore;

	assign wRs1Valid = (!iFalseRs1) && (iRs1Addr != 5'b0);
	assign wRs2Valid = (!iFalseRs2) && (iRs2Addr != 5'b0);
	assign wLoadStoreValid = (iExRdAddr != 5'b0) && (!iFalseLoadStore);

	assign wRs1LoadStore = (iRs1Addr == iExRdAddr) && wRs1Valid && wLoadStoreValid;
	assign wRs2LoadStore = (iRs2Addr == iExRdAddr) && wRs2Valid && wLoadStoreValid;
	asign oHazard = wRs1LoadStore || wRs2LoadStore;
	oFlush = iFlush;

endmodule
