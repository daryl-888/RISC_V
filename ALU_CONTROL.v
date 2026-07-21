module ALU_CONTROL (
    input [2:0] iAluOp,
    input [2:0] iFunct3,
    input [6:0] iFunct7,
    output reg [3:0] oAluCtrl
);
    // ALU operation
    localparam ADD = 4'b0000;
    localparam SUB = 4'b1000;
    localparam SLL = 4'b0001;
    localparam SRL = 4'b0101;
    localparam SRA = 4'b1101;
    localparam SLT = 4'b0010;
    localparam SLTU = 4'b0011;
    localparam XOR = 4'b0100;
    localparam OR = 4'b0110;
    localparam AND = 4'b0111;
    localparam BEQ = 4'b1001;
    localparam BNE = 4'b1100;
    localparam BLT = 4'b1010;
    localparam BGE = 4'b1110;
    localparam BLTU = 4'b1011;
    localparam BGEU = 4'b1111;

    // ALU opcode
    localparam REG_ARTH = 3'b011;
    localparam IMM_ARTH = 3'b001;
    localparam LOAD = 3'b000;
    localparam STORE = 3'b010;
    localparam BRANCH_JUMP = 3'b110;


    always @(*) begin
        case (iAluOp)

            LOAD:  oAluCtrl = ADD;
            STORE: oAluCtrl = ADD;

            // R-type: funct7[5] + funct3
            REG_ARTH: oAluCtrl = {iFunct7[5], iFunct3};

            IMM_ARTH: oAluCtrl = (iFunct3 == 3'b001 || iFunct3 == 3'b101)  // is it a shift?
                     ? {iFunct7[5], iFunct3}   // yes: bit 30 picks SRLI vs SRAI
                     : {1'b0, iFunct3};        // no: bit 30 is immediate data, ignore it

            BRANCH_JUMP: case (iFunct3)
                3'b000:  oAluCtrl = BEQ;
                3'b001:  oAluCtrl = BNE;
                3'b100:  oAluCtrl = BLT;
                3'b101:  oAluCtrl = BGE;
                3'b110:  oAluCtrl = BLTU;
                3'b111:  oAluCtrl = BGEU;

                default: oAluCtrl = ADD;   
            endcase


            default: oAluCtrl = ADD;
        endcase
    end


endmodule
