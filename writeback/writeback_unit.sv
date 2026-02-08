module writeback_unit #(
    parameter PR_BITS  = 6,
    parameter ROB_BITS = 4
)(
    // -----------------------------------------------------
    // INPUTS FROM EXECUTION UNITS
    // -----------------------------------------------------
    // From ALU
    input  logic                alu_wb_valid,
    input  logic [31:0]         alu_wb_data,
    input  logic [PR_BITS-1:0]  alu_wb_phys,
    input  logic [ROB_BITS-1:0] alu_wb_rob_idx,

    // From Memory System (D-Cache / MSHR)
    input  logic                mem_wb_valid,
    input  logic [31:0]         mem_wb_data,
    input  logic [PR_BITS-1:0]  mem_wb_phys,
    input  logic [ROB_BITS-1:0] mem_wb_rob_idx,

    // -----------------------------------------------------
    // OUTPUTS TO PIPELINE (The Broadcast / CDB)
    // -----------------------------------------------------
    // To Physical Register File (PRF) - The Storage
    output logic                prf_we,
    output logic [PR_BITS-1:0]  prf_waddr,
    output logic [31:0]         prf_wdata,

    // To Reservation Station (RS) - The Wakeup Logic
    output logic                rs_wakeup_valid,
    output logic [PR_BITS-1:0]  rs_wakeup_phys,

    // To Reorder Buffer (ROB) - The Completion Status
    output logic                rob_wb_en,
    output logic [ROB_BITS-1:0] rob_wb_idx
);

    /* =====================================================
       RESULT ARBITRATION (The "Multiplexer")
       In high-performance OoO, Memory results usually get 
       priority because their arrival is unpredictable.
       ===================================================== */
    always_comb begin
        // Default: No activity
        prf_we          = 1'b0;
        prf_waddr       = '0;
        prf_wdata       = '0;
        rs_wakeup_valid = 1'b0;
        rs_wakeup_phys  = '0;
        rob_wb_en       = 1'b0;
        rob_wb_idx      = '0;

        if (mem_wb_valid) begin
            // 1. DATA FROM MEMORY SYSTEM (D-Cache Hit or MSHR Refill)
            prf_we          = 1'b1;
            prf_waddr       = mem_wb_phys;
            prf_wdata       = mem_wb_data;
            
            rs_wakeup_valid = 1'b1;
            rs_wakeup_phys  = mem_wb_phys;
            
            rob_wb_en       = 1'b1;
            rob_wb_idx      = mem_wb_rob_idx;

        end else if (alu_wb_valid) begin
            // 2. DATA FROM ALU (Arithmetic / Logic)
            // Note: We check (alu_wb_phys != 0) to avoid writing to x0
            prf_we          = (alu_wb_phys != 0); 
            prf_waddr       = alu_wb_phys;
            prf_wdata       = alu_wb_data;
            
            rs_wakeup_valid = 1'b1;
            rs_wakeup_phys  = alu_wb_phys;
            
            rob_wb_en       = 1'b1;
            rob_wb_idx      = alu_wb_rob_idx;
        end
    end

endmodule