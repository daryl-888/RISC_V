module ALU (
    input [31:0] iDataA, // First 32 bit input operand
    input [31:0] iDataB, // Second 32 bit input operand
    input [3:0] iAluCtrl,  // 4 bit ALU operation code
    output reg [31:0] oData, // Output 32 bit result
    output reg oBranch
);
    // ALU operation
    localparam ADD = 4'b0000;
    localparam SUB = 4'b1000;
    localparam SLL = 4'b0001;
    localparam SRL = 4'b0101;
    localparam SRA = 4'b1101;
    localparam SLT = 4'b0010; // signed less than
    localparam SLTU = 4'b0011; // unsigned less than
    localparam XOR = 4'b0100;
    localparam OR  = 4'b0110;
    localparam AND = 4'b0111;
    localparam BEQ  = 4'b1001;
    localparam BNE  = 4'b1100;
    localparam BLT  = 4'b1010;
    localparam BGE  = 4'b1110;
    localparam BLTU = 4'b1011;
    localparam BGEU = 4'b1111;

    always @(*) begin
        case (iAluCtrl)
            ADD:  begin
                oData = iDataA + iDataB;
                oBranch = 1'b0;
            end
            SUB:  begin
                oData = iDataA - iDataB;
                oBranch = 1'b0;
            end
            SLL:  begin
                oData = iDataA << iDataB[4:0];
                oBranch = 1'b0;
            end
            SRL:  begin
                oData = iDataA >> iDataB[4:0];
                oBranch = 1'b0;
            end
            SRA:  begin
                oData = $signed(iDataA) >>>  iDataB[4:0];
                oBranch = 1'b0;
            end
            SLT:  begin
                oData = (iDataA < iDataB) ? 1 : 0;
                oBranch = 1'b0;
            end
            SLTU: begin
                oData = ($unsigned(iDataA) < $unsigned(iDataB)) ? 1'b1 : 1'b0;
                oBranch = 1'b0;
            end
            XOR:  begin
                oData = iDataA ^ iDataB;
                oBranch = 1'b0;
            end
            OR:   begin
                oData = iDataA | iDataB;
                oBranch = 1'b0;
            end
            AND:  begin
                oData = iDataA & iDataB;
                oBranch = 1'b0;
            end
            BEQ:  begin
                oData = iDataA - iDataB;
                oBranch = (oData == 32'b0);
            end
            BNE:  begin
                oData = iDataA - iDataB;
                oBranch = (oData != 32'b0);
            end
            BLT:  begin
                oData = iDataA - iDataB;
                oBranch = ($signed(iDataA) < $signed(iDataB));
            end
            BGE:  begin
                oData = iDataA - iDataB;
                oBranch = ($signed(iDataA) >= $signed(iDataB));
            end
            BLTU: begin
                oData = iDataA - iDataB;
                oBranch = ($unsigned(iDataA) < $unsigned(iDataB));
            end
            BGEU: begin
                oData = iDataA - iDataB;
                oBranch = ($unsigned(iDataA) >= $unsigned(iDataB));
            end
            default: begin
                oData = 32'b0;
                oBranch = 1'b0;
            end
        endcase
    end
endmodule
