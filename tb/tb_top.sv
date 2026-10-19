// Testbench wrapper. The C++ harness (sim_main.cpp) drives the clock and reset;
// when it raises `dump`, this module writes the register file and data memory
// to dut_state.txt so run_tests.py can compare them with the Python model.
// The core loads instr.txt / data.txt from the current directory.
module tb_top (
    input logic clk,
    input logic rst_n,
    input logic dump
);
    integer i, f;

    RISCV_TOP dut (.iClk(clk), .iRstN(rst_n));

    always @(posedge dump) begin
        f = $fopen("dut_state.txt", "w");
        for (i = 0; i < 32; i = i + 1)
            $fdisplay(f, "R %0d %08x", i, dut.u_id.register.registers[i]);
        for (i = 0; i < 4096; i = i + 1)
            $fdisplay(f, "M %0d %02x", i, dut.u_mem.data_memory_unit.rDataMem[i]);
        $fclose(f);
    end
endmodule
