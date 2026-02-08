module memory_system #(
    parameter PR_BITS  = 6,
    parameter ROB_BITS = 4,
    parameter LSQ_SIZE = 8
)(
    input  logic        clk,
    input  logic        rst,
    
    // -----------------------------------------------------
    // PIPELINE INTERFACE (Dispatch & Execution)
    // -----------------------------------------------------
    input  logic        mem_alloc_en,
    input  logic        mem_is_store,
    input  logic [PR_BITS-1:0]  mem_rd_phys,
    input  logic [ROB_BITS-1:0] mem_rob_idx,
    output logic        mem_lsq_full,
    

    input  logic        mem_exec_en,
    input  logic [$clog2(LSQ_SIZE)-1:0] mem_exec_idx,
    input  logic [31:0] rs1_val,    // Base address from PRF
    input  logic [31:0] imm,        // Offset from Issue Queue
    input  logic [31:0] rs2_val,    // Store data from PRF

    // -----------------------------------------------------
    // COMMIT INTERFACE (From ROB)
    // -----------------------------------------------------
    input  logic        mem_commit_en,
    input  logic [ROB_BITS-1:0] mem_commit_rob_idx,
    // -----------------------------------------------------
    // EXTERNAL MAIN MEMORY INTERFACE (The bottom of diagram)
    // -----------------------------------------------------
    output logic [31:0] main_mem_addr,
    output logic        main_mem_req,
    input  logic [31:0] main_mem_data_in,
    input  logic        main_mem_ready,
    input logic flush,

    // -----------------------------------------------------
    // WRITEBACK BUS (To PRF, ROB, and Issue Queue Wakeup)
    // -----------------------------------------------------
    output logic        wb_valid,
    output logic [PR_BITS-1:0] wb_phys,
    output logic [31:0] wb_data
);

    // Internal Signals linking the blocks
    logic [31:0] lsu_to_cache_addr;
    logic [31:0] lsu_to_cache_wdata;
    logic        lsu_re, lsu_we;

    
    logic [31:0] cache_to_lsu_rdata;
    logic        cache_hit, cache_miss;
    logic [$clog2(LSQ_SIZE)-1:0] mem_lsq_idx;

    logic        mshr_wb_valid;
    logic [PR_BITS-1:0] mshr_wb_phys;
    logic [31:0] mshr_wb_data;

    logic        lsu_wb_valid;
    logic [PR_BITS-1:0] lsu_wb_phys;
    logic [31:0] lsu_wb_data;

    // -----------------------------------------------------
    // 1. LSU (Load/Store Unit & Data Address Calculation)
    // -----------------------------------------------------
    lsu #(LSQ_SIZE, PR_BITS, ROB_BITS) u_lsu (
        .clk(clk), .rst(rst),
        .lsu_idx(mem_lsq_idx),
        // Pipeline
        .lsu_alloc_en(mem_alloc_en),
        .lsu_is_store(mem_is_store),
        .lsu_rd_phys(mem_rd_phys),
        .lsu_rob_idx(mem_rob_idx),
        .lsu_full(mem_lsq_full),
        .flush(flush),
        // Execute
        .lsu_exec_en(mem_exec_en),
        .lsu_exec_idx(mem_exec_idx),
        .rs1_val(rs1_val),
        .imm(imm),
        .rs2_val(rs2_val),
        // Commit
        .lsu_commit_en      (mem_commit_en),
        .lsu_commit_rob_idx (mem_commit_rob_idx),
        // Cache Interface
        .dcache_addr(lsu_to_cache_addr),
        .dcache_wdata(lsu_to_cache_wdata),
        .dcache_re(lsu_re),
        .dcache_we(lsu_we),
        .dcache_rdata(cache_to_lsu_rdata),
        .dcache_hit(cache_hit),
        // Result
        .lsu_wb_valid(lsu_wb_valid),
        .lsu_wb_phys(lsu_wb_phys),
        .lsu_wb_data(lsu_wb_data)
    );

    // -----------------------------------------------------
    // 2. DATA CACHE (D-Cache)
    // -----------------------------------------------------
    d_cache u_dcache (
        .clk(clk),
        .addr(lsu_to_cache_addr),
        .wdata(lsu_to_cache_wdata),
        .read_en(lsu_re),
        .write_en(lsu_we),
        .rdata(cache_to_lsu_rdata),
        .hit(cache_hit),
        .miss(cache_miss)
    );

    // -----------------------------------------------------
    // 3. MSHR (Miss Status Holding Register)
    // -----------------------------------------------------
    mshr #(4, PR_BITS) u_mshr (
        .clk(clk), .rst(rst),
        .miss_occurred(cache_miss),
        .miss_addr(lsu_to_cache_addr),
        .target_reg(mem_rd_phys),
        // To Main Mem
        .mem_req_valid(main_mem_req),
        .mem_req_addr(main_mem_addr),
        // From Main Mem
        .mem_resp_valid(main_mem_ready),
        .mem_resp_data(main_mem_data_in),
        // Wakeup
        .wb_valid(mshr_wb_valid),
        .wb_phys(mshr_wb_phys),
        .wb_data(mshr_wb_data)
    );

    // -----------------------------------------------------
    // 4. WRITE-BACK ARBITRATION (Final output to Pipeline)
    // -----------------------------------------------------
    // Data can return from the Cache (Hit) or MSHR (Memory response)
    always_comb begin
        if (mshr_wb_valid) begin
            wb_valid = 1'b1;
            wb_phys  = mshr_wb_phys;
            wb_data  = mshr_wb_data;
        end else begin
            wb_valid = lsu_wb_valid;
            wb_phys  = lsu_wb_phys;
            wb_data  = lsu_wb_data;
        end
    end

endmodule