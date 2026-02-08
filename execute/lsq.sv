module lsq #(
    parameter LSQ_SIZE = 8,
    parameter PR_BITS  = 6,
    parameter ROB_BITS = 4
)(

    input  logic        clk,
    input  logic        rst,

    // Dispatch (from Rename)
    input  logic        alloc_en,
    input  logic        is_store,
    input  logic [PR_BITS-1:0] rd_phys, // For Loads
    input  logic [ROB_BITS-1:0] alloc_rob_idx, 
    output logic [$clog2(LSQ_SIZE)-1:0] lsq_idx,

    // Execute (Address Calculation from ALU)
    input  logic        addr_valid,
    input  logic [$clog2(LSQ_SIZE)-1:0] exec_idx,
    input  logic [31:0] computed_addr,
    input  logic [31:0] store_data,

    // Commit (Store can finally write to D-Cache)
    input  logic        commit_en,
    input  logic [ROB_BITS-1:0] commit_rob_idx,
    output logic [31:0] mem_addr,
    output logic [31:0] mem_data,
    output logic        mem_write_en
);

    typedef struct packed {
        logic valid;
        logic is_store;
        logic addr_ready;
        logic [31:0] addr;
        logic [31:0] data;
        logic [PR_BITS-1:0] rd_phys;
        logic [ROB_BITS-1:0] rob_idx;
    } lsq_entry_t;

    lsq_entry_t lsq_mem [LSQ_SIZE-1:0];
    logic [$clog2(LSQ_SIZE)-1:0] head, tail;
    logic lsq_full;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            head <= 0; tail <= 0;
            for(int i=0; i<LSQ_SIZE; i++) lsq_mem[i].valid <= 0;
        end else begin
            // Allocate entry at Dispatch
            if (alloc_en && !lsq_full) begin
                lsq_mem[tail].valid    <= 1'b1;
                lsq_mem[tail].is_store <= is_store;
                lsq_mem[tail].rd_phys  <= rd_phys;
                lsq_mem[tail].rob_idx  <= alloc_rob_idx;
                lsq_mem[tail].addr_ready <= 0;
                tail <= tail + 1;
            end

            // Update with computed address from ALU
            if (addr_valid) begin
                lsq_mem[exec_idx].addr       <= computed_addr;
                lsq_mem[exec_idx].data       <= store_data;
                lsq_mem[exec_idx].addr_ready <= 1'b1;
            end

            // Retire/Commit: If head is a store, send to D-Cache
if (commit_en &&
    lsq_mem[head].valid &&
    lsq_mem[head].is_store &&
    lsq_mem[head].rob_idx == commit_rob_idx) begin

    lsq_mem[head].valid <= 1'b0;
    head <= head + 1;
end
        end
    end

    assign lsq_idx = tail;
    assign mem_addr = (lsq_mem[head].valid) ? lsq_mem[head].addr : '0;
    assign mem_data = (lsq_mem[head].valid) ? lsq_mem[head].data : '0;

    assign mem_write_en =
    commit_en &&
    lsq_mem[head].valid &&
    lsq_mem[head].is_store &&
    (lsq_mem[head].rob_idx == commit_rob_idx);
    assign lsq_full =
    ((tail + 1'b1) == head);

endmodule