module HAZARD (
    input iFalseRs1,
    input iFalseRs2,
    input iFalseLoadStore,
    input iFlush,
    input [4:0] iRs1Addr,
    input [4:0] iRs2Addr,
    input [4:0] iExRdAddr,
    output oHazard,
    output oFlush
);
    wire wRs1Valid, wRs2Valid, wLoadStoreValid;
    wire wRs1LoadStore, wRs2LoadStore;

    assign wRs1Valid = // valid rs1 (if its false thrown from imm value matching a register addr by coincedence.)
    assign wRs2Valid = // valid rs2
    assign wLoadStoreValid = // valid load->store hazard

    assign wRs1LoadStore = // load->store hazard for rs1
    assign wRs2LoadStore = // load->store hazard for rs2
    assign oHazard = // Hazard flag, considers load->store hazard
    assign oFlush =  // Flush flag
endmodule
