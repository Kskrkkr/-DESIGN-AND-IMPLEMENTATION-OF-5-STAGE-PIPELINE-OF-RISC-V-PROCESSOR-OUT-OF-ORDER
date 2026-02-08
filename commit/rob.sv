module rob #(
    parameter ROB_SIZE = 16,
    parameter ROB_BITS = $clog2(ROB_SIZE)
)(
    input  logic clk,
    input  logic rst,

    // =========================
    // CONTROL
    // =========================
    input  logic flush,                      // branch mispredict
    input  logic [ROB_BITS-1:0] flush_idx,   // correct tail position

    // =========================
    // Allocate (Rename)
    // =========================
    input  logic                alloc_en,
    input  logic [4:0]          rd_arch,
    input  logic [5:0]          rd_phys,
    input  logic [5:0]          old_phys,
    output logic [ROB_BITS-1:0] alloc_idx,

    // =========================
    // Writeback
    // =========================
    input  logic                wb_en,
    input  logic [ROB_BITS-1:0] wb_idx,

    // =========================
    // Commit
    // =========================
    output logic                commit_valid,
    output logic [4:0]          commit_rd_arch,
    output logic [5:0]          free_phys,
    output logic [ROB_BITS-1:0] commit_idx
);

    // =========================
    // ROB Entry
    // =========================
    typedef struct packed {
        logic       valid;
        logic       done;
        logic [4:0] rd_arch;
        logic [5:0] rd_phys;
        logic [5:0] old_phys;
    } rob_entry_t;

    rob_entry_t rob_mem [ROB_SIZE];

    logic [ROB_BITS-1:0] head, tail;

    // =========================
    // ROB State Machine
    // =========================
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            head <= '0;
            tail <= '0;
            for (int i = 0; i < ROB_SIZE; i++)
                rob_mem[i] <= '0;
        end
        else if (flush) begin
            // Precise state recovery
            tail <= flush_idx;
        end
        else begin
            // -------------------------
            // Allocate (NO x0)
            // -------------------------
            if (alloc_en && rd_arch != 0 && ((tail + 1'b1) != head)) begin
                rob_mem[tail].valid    <= 1'b1;
                rob_mem[tail].done     <= 1'b0;
                rob_mem[tail].rd_arch  <= rd_arch;
                rob_mem[tail].rd_phys  <= rd_phys;
                rob_mem[tail].old_phys <= old_phys;
                tail <= tail + 1'b1;
            end

            // -------------------------
            // Writeback
            // -------------------------
            if (wb_en) begin
                rob_mem[wb_idx].done <= 1'b1;
            end

            // -------------------------
            // Commit (Head only)
            // -------------------------
            if (rob_mem[head].valid && rob_mem[head].done) begin
                rob_mem[head].valid <= 1'b0;
                head <= head + 1'b1;
            end
        end
    end

    // =========================
    // Outputs
    // =========================
    assign commit_valid   = rob_mem[head].valid &&
                            rob_mem[head].done &&
                            (rob_mem[head].rd_arch != 0);

    assign commit_rd_arch = rob_mem[head].rd_arch;
    assign free_phys      = rob_mem[head].old_phys;
    assign commit_idx     = head;
    assign alloc_idx      = tail;

    // =========================
    // Debug (safe)
    // =========================
    always_ff @(posedge clk) begin
        if (commit_valid) begin
            $display("[COMMIT] x%0d committed", commit_rd_arch);
        end
    end

    always_ff @(posedge clk) begin
    if (wb_en) begin
        $display("[ROB WB] idx=%0d", wb_idx);
    end
    if (commit_valid) begin
        $display("[ROB COMMIT] idx=%0d rd=x%0d",
                 commit_idx, commit_rd_arch);
    end
end

endmodule
