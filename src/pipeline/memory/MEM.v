`timescale 1ns / 1ps

`include "memory/DATA_MEMORY.v"

/*
 * Memory Access (MEM) Stage
 *
 * Purpose:
 * 1. Performs read or write operations to the Data Memory for load/store instructions.
 * 2. Passes the ALU result and control signals to the WB stage.
 *
 * Inputs:
 * - Data and control signals from the EX/MEM pipeline register.
 *
 * Outputs:
 * - Data read from memory (for loads).
 * - ALU result (passed through from EX).
 * - Control signals and destination register for the WB stage.
 */
module MEM (
    input iClk,
    input iRstN,

    // Inputs from EX/MEM Pipeline Register
    input [31:0] iAluResult, // Address for memory or result for WB
    input [31:0] iRs2Data,   // Data to write for store instructions
    input [4:0]  iRd,        // Destination register for WB
    input [2:0]  iFunct3,    // Load/store width (LB/LH/LW/LBU/LHU, SB/SH/SW)
    input        iMemRd,
    input        iMemWr,
    input        iMemtoReg,
    input        iRegWrite,

    // Outputs to MEM/WB Pipeline Register
    output reg [31:0] oMemData,
    output reg [31:0] oAluResult,
    output reg [4:0]  oRd,
    output reg oMemtoReg,
    output reg oRegWrite
);

    wire [31:0] wMemData;

    // Data memory access. Address is the ALU result from EX.
    DATA_MEMORY data_memory_unit (
        .iClk       (iClk),
        .iAddress   (iAluResult),
        .iWriteData (iRs2Data),
        .iFunct3    (iFunct3),
        .iMemWrite  (iMemWr),
        .iMemRead   (iMemRd),
        .oReadData  (wMemData)
    );

    // --- Sequential Logic (MEM/WB Pipeline Register) ---
    always @(posedge iClk or negedge iRstN) begin
        if (!iRstN) begin
            oMemData   <= 32'b0;
            oAluResult <= 32'b0;
            oRd        <= 5'b0;
            oMemtoReg  <= 1'b0;
            oRegWrite  <= 1'b0;
        end else begin
            oMemData   <= wMemData;
            oAluResult <= iAluResult;
            oRd        <= iRd;
            oMemtoReg  <= iMemtoReg;
            oRegWrite  <= iRegWrite;
        end
    end

endmodule
