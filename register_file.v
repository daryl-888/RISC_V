// combinational : sequential
// combinational -
// sequential    -

module regfile (
  input i_clk,
  input i_rstn,
  input i_wr_en,
  input [4:0] i_rd_addr,
  input [4:0] i_rs1_addr,
  input [4:0] i_rs2_addr,
  input [31:0] i_rd_data,
  output [31:0] o_rs1_data,
  output [31:0] o_rs2_data,
);

	reg [31:0] registers [1:31];

	assign o_rs1_data = (o_rs1_addr == 5'b0) ? 32'b0 : registers[o_rs1_addr];
	assign o_rs2_data = (o_rs2_addr == 5'b0) ? 32'b0 : registers[o_rs2_addr];

	integer i;
    always@(posedge i_clk or negedge i_rstn) begin
		if (!i_rstn) begin
           for (i = 0; i < 32; i = i + 1) begin
				registers[i] <= 32'b0;
			end
        end else begin
            if (i_wr_en && i_rd_addr != 5'b0) begin
                registers[i_rd_addr] <= i_rd_data;
            end
        end
    end
endmodule
