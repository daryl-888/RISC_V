// Verilator C++ harness: reset, run +cycles=N clock cycles, then dump state.
#include "Vtb_top.h"
#include "verilated.h"
#include <cstdlib>
#include <cstring>

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);
    long cycles = 500;
    const char* arg = Verilated::commandArgsPlusMatch("cycles=");
    if (arg && std::strlen(arg) > 8) cycles = std::atol(arg + 8);  // "+cycles=N"

    Vtb_top* top = new Vtb_top;
    top->clk = 0; top->rst_n = 0; top->dump = 0;
    top->eval();
    for (int i = 0; i < 2; ++i) { top->clk = 1; top->eval(); top->clk = 0; top->eval(); }
    top->rst_n = 1; top->eval();

    for (long c = 0; c < cycles; ++c) {
        top->clk = 1; top->eval();
        top->clk = 0; top->eval();
    }
    top->dump = 1; top->eval();
    top->final();
    delete top;
    return 0;
}
