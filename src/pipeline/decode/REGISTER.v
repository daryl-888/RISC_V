// Register module definition
module REGISTER (
    input iClk,              // Clock input
    input iRstN,             // Active low reset input
    input iWriteEn,          // Write enable input
    input [4:0] iRdAddr,     // 5 bit register address input
    input [4:0] iRs1Addr,    // 5 bit source register 1 address input
    input [4:0] iRs2Addr,    // 5 bit source register 2 address input
    input [31:0] iWriteData, // 32 bit data input to store in register
    output [31:0] oRs1Data,  // 32 bit source register 1 data output
    output [31:0] oRs2Data   // 32 bit source register 2 data output
);
    integer i;
    // 32 registers, 32-bit each (x0 - x31)
    reg [31:0] registers [0:31];

    // Read logic (asynchronous, active when read enable is high)
    // x0 is hardwired to 0
    assign oRs1Data = (iRs1Addr == 5'b0 ? 32'b0 :
                      (iWriteEn && iRdAddr == iRs1Addr) ? iWriteData :
                                                          registers[iRs1Addr]);
    assign oRs2Data = (iRs2Addr == 5'b0 ? 32'b0 :
                      (iWriteEn && iRdAddr == iRs2Addr) ? iWriteData :
                                                          registers[iRs2Addr]);

    // Write logic (synchronous)
    always @(posedge iClk or negedge iRstN) begin
        if (!iRstN) begin
            // Reset logic: Initialize all registers to zero
            for (i = 0; i < 32; i = i + 1) begin
                registers[i] <= 32'b0;
            end
        end else begin
            // Write logic: x0 cannot be written (always 0)
            if (iWriteEn && iRdAddr != 5'b0) begin
                registers[iRdAddr] <= iWriteData;
            end
        end
    end
endmodule

