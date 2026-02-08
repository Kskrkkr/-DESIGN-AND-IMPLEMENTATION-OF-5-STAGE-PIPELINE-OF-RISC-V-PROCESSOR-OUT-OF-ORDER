module mem_arbiter (
    input  logic        clk,
    input  logic        rst,

    // Interface from I-Cache (Instruction Miss)
    input  logic        icache_req,
    input  logic [31:0] icache_addr,
    output logic        icache_grant,

    // Interface from D-Cache/MSHR (Data Miss)
    input  logic        dcache_req,
    input  logic [31:0] dcache_addr,
    output logic        dcache_grant,

    // Interface to actual Main Memory
    output logic [31:0] main_mem_addr,
    output logic        main_mem_valid
);
    // Fixed Priority: Data misses (MSHR) usually get priority over Instruction fetches
    always_comb begin
        icache_grant   = 1'b0;
        dcache_grant   = 1'b0;
        main_mem_valid = 1'b0;
        main_mem_addr  = 32'h0;

        if (dcache_req) begin
            dcache_grant   = 1'b1;
            main_mem_addr  = dcache_addr;
            main_mem_valid = 1'b1;
        end else if (icache_req) begin
            icache_grant   = 1'b1;
            main_mem_addr  = icache_addr;
            main_mem_valid = 1'b1;
        end
    end
endmodule