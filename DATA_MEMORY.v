module DATA_MEMORY (
    input iClk,
    input [31:0] iAddress,
    input [31:0] iWriteData,
    input [2:0] iFunct3,
    input iMemWrite,
    input iMemRead,
    output [31:0] oReadData
);

	localparam B = 8;
    localparam K = 1024;

    // load
    localparam LB = 3'b000;
    localparam LH = 3'b001;
    localparam LW = 3'b010;
    localparam LBU = 3'b100;
    localparam LHU = 3'b101;

    // store
    localparam SB = 3'b000;
    localparam SH = 3'b001;
    localparam SW = 3'b010;

    reg [B-1:0] rDataMem [0:(K*4)-1]; // 4KB data memory, byte-addressable

    initial begin
        $readmemh("data.txt", rDataMem);
    end

    assign oReadData = (!iMemRead) ? 32'b0 :
      				   (iFunct3 == LB) ? {{24{rDataMem[iAddress][7]}}, rDataMem[iAddress]} :
					   (iFunct3 == LH) ? {{16{rDataMem[iAddress + 1][7]}}, rDataMem[iAddress + 1], rDataMem[iAddress]} :
					   (iFunct3 == LW) ? {rDataMem[iAddress+3], rDataMem[iAddress+2], rDataMem[iAddress+1], rDataMem[iAddress]} :
					   (iFunct3 == LBU) ? {24'b0, rDataMem[iAddress]} :
                       (iFunct3 == LHU) ? {16'b0, rDataMem[iAddress + 1], rDataMem[iAddress]} :
                       32'b0;

	always @(posedge iClk) begin
    	if (iMemWrite) begin
        case (iFunct3)
              	SB: rDataMem[iAddress] <= iWriteData[7:0];
                SH: begin
                	rDataMem[iAddress] <= iWriteData[7:0];
                    rDataMem[iAddress + 1] <= iWriteData[15:8];
                end
                SW: begin
                    rDataMem[iAddress]   <= iWriteData[7:0];
                    rDataMem[iAddress+1] <= iWriteData[15:8];
                    rDataMem[iAddress+2] <= iWriteData[23:16];
                    rDataMem[iAddress+3] <= iWriteData[31:24];
                end
                default: ;
            endcase
        end
    end
endmodule
