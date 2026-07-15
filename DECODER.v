// RISCV-32I

// Combinational
`default_nettype none

module decoder (
  input [31:0] i_instr,
  output [6:0] o_opcode,
  output [4:0] o_rd,
  output [2:0] o_funct3,
  output [4:0] o_rs1,
  output [4:0] o_rs2,
  output [6:0] o_funct7,
  output [31:0] o_imm
);

  localparam R_TYPE = 7'b0110011, I_TYPE = 7'b0010011, U_TYPE = 7'b0110111, U_TYPE_AUIPC = 7'b0010111, I_TYPE_LOAD = 7'b0000011;
  localparam S_TYPE = 7'b0100011, B_TYPE = 7'b1100011, J_TYPE = 7'b1101111, I_TYPE_JALR = 7'b1100111;

  assign o_opcode = i_instr[6:0];
  assign o_rd = i_instr[11:7];
  assign o_funct3 = i_instr[14:12];
  assign o_rs1 = i_instr[19:15];
  assign o_rs2 = i_instr[24:20];
  assign o_funct7 = i_instr[31:25];

  // Ternary operator
  // assign value = (condition) ? TRUE : FALSE;

  // Concatination
  // combine two vectors into one vector
  // wire [5:0] a, b; (6 bit)
  // wire [11:0] c;   (12 bit)
  // assign wire c = {a, b};

  assign o_imm = (o_opcode == I_TYPE || o_opcode == I_TYPE_LOAD || o_opcode == I_TYPE_JALR) ? {{21{i_instr[31]}}, i_instr[30:20]} :
                 (o_opcode == U_TYPE || o_opcode == U_TYPE_AUIPC) ? {i_instr[31:12], 12'b0} :
                 (o_opcode == S_TYPE) ? {{21{i_instr[31]}}, i_instr[30:25], i_instr[11:7]} :
                 (o_opcode == B_TYPE) ? {{20{i_instr[31]}}, i_instr[7], i_instr[30:25], i_instr[11:8], 1'b0} :
                 (o_opcode == J_TYPE) ? {{12{i_instr[31]}}, i_instr[19:12], i_instr[20], i_instr[30:25], i_instr[24:21], 1'b0} :
                 32'b0;

endmodule
`default_nettype wire
