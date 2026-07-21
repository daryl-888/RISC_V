module IF (
	input iClk,
    input iRstN,
  	input iPcSrc,
    input iHazard,
    input iFlush,
    input [31:0] iPc,
    output reg [31:0] oPc,
    output reg [31:0] oInstr
);

	localparam NOP = 32'h13;

    reg [31:0] rPc;
	wire [31:0] wNextPc;

	assign wNextPc = rPc + 32'h4;

    always@(posedge iClk or negedge iRstN) begin
    	if(!iRstN) begin
        	rPc    <= 32'h0;
          	oPc    <= 32'h0;
          	oInstr <= 32'h13;
        end else begin
        	if(iFlush) begin
            	oPc <= 0;
				oInstr <= NOP;

				case(iPcSrc)
                	1'b0: rPc <= wNextPc; // PC is correct
                  	1'b1: rPc <= iPc; // PC is wrong
                endcase
            end else begin
            	if(!Hazard) begin
                	case(iPcSrc)
                    	1'b0: rPc <= wNextPc;
                      	1'b1: rPc <= iPc;
                    endcase

                    oPc <= rPc;
					oInstr <= wInstr;
                end
            end
        end
    end
endmodule
