`timescale 1ns / 1ps
/*
 * Hazard Detection Unit
 *
 * Purpose:
 * Detects load-use hazards and signals the pipeline to stall.
 *
 * A load-use hazard occurs when an instruction in the ID stage depends on the
 * result of a load instruction currently in the EX stage. The data from memory
 * will not be ready in time for the ALU in the next cycle, requiring a one-cycle stall.
 */
module HAZARD (
    // Inputs from ID/EX pipeline register (the instruction in the EX stage)
    input        iIdExMemRead, // Is the instruction in EX a load?
    input [4:0]  iIdExRd,      // Destination register of the instruction in EX
    // Inputs from IF/ID pipeline register (the instruction in the ID stage)
    input [4:0]  iIfIdRs1,     // Source register 1 of the instruction in ID
    input [4:0]  iIfIdRs2,     // Source register 2 of the instruction in ID
    // Outputs to control pipeline flow
    output reg   oPcStall,     // Stalls the PC and IF/ID register
    output reg   oBubble       // Injects a NOP (bubble) into the ID/EX register
);

    always @(*) begin
        // Check for the load-use hazard condition:
        // An instruction in the EX stage is a load (iIdExMemRead) AND
        // its destination register (iIdExRd) is not x0 AND
        // it matches one of the source registers of the instruction in the ID stage.
        if (iIdExMemRead && (iIdExRd != 5'b0) && ((iIdExRd == iIfIdRs1) || (iIdExRd == iIfIdRs2))) begin
            oPcStall = 1'b1; // Stall the PC and the IF/ID register.
            oBubble  = 1'b1; // Force a NOP into the ID/EX register.
        end else begin
            // No hazard, pipeline proceeds normally.
            oPcStall = 1'b0;
            oBubble  = 1'b0;
        end
    end

endmodule
