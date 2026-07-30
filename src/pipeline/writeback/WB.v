`timescale 1ns / 1ps

/*
 * Write-Back (WB) Stage
 *
 * Purpose:
 * 1. Selects the final data to be written back to the register file.
 *    - Either the result from the ALU or the data from memory.
 * 2. Provides the data, destination address, and write enable signal to the register file.
 *
 * This is the final stage and is purely combinational. The actual write to the
 * register file happens at the clock edge, driven from ID.v (the register
 * file physically lives in the ID stage since it's read there too).
 */
module WB (
    // Inputs from MEM/WB Pipeline Register
    input [31:0] iAluResult,
    input [31:0] iMemData,
    input [4:0]  iRd,
    input        iMemtoReg,
    input        iRegWrite,

    // Outputs to Register File
    output [31:0] oRegWrData,
    output [4:0]  oRegWrAddr,
    output        oRegWrEn
);

    assign oRegWrData = iMemtoReg ? iMemData : iAluResult;
    assign oRegWrAddr = iRd;
    assign oRegWrEn   = iRegWrite;

endmodule
