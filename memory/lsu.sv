module lsu #(
    parameter LSQ_SIZE = 8,
    parameter PR_BITS  = 6,
    parameter ROB_BITS = 4
)(
    input  logic        clk,
    input  logic        rst,

    /* ---------------- DISPATCH ---------------- */
    input  logic        lsu_alloc_en,
    input  logic        lsu_is_store,
    input  logic [PR_BITS-1:0]  lsu_rd_phys,
    input  logic [ROB_BITS-1:0] lsu_rob_idx,
    output logic [$clog2(LSQ_SIZE)-1:0] lsu_idx,
    output logic        lsu_full,

    /* ---------------- EXECUTE ---------------- */
    input  logic        lsu_exec_en,
    input  logic [$clog2(LSQ_SIZE)-1:0] lsu_exec_idx,
    input  logic [31:0] rs1_val,
    input  logic [31:0] imm,
    input  logic [31:0] rs2_val,

    /* ---------------- COMMIT ---------------- */
    input  logic        lsu_commit_en,
    input  logic [ROB_BITS-1:0] lsu_commit_rob_idx,

    /* ---------------- CACHE ---------------- */
    output logic [31:0] dcache_addr,
    output logic [31:0] dcache_wdata,
    output logic        dcache_re,
    output logic        dcache_we,
    input  logic [31:0] dcache_rdata,
    input  logic        dcache_hit,
    input logic flush,

    /* ---------------- WRITEBACK ---------------- */
    output logic        lsu_wb_valid,
    output logic [PR_BITS-1:0] lsu_wb_phys,
    output logic [31:0] lsu_wb_data
);

    typedef enum logic [1:0] {
        LSQ_IDLE,
        LSQ_WAIT_MEM,
        LSQ_DONE
    } lsq_state_t;

    typedef struct packed {
        logic        valid;
        logic        is_store;
        logic        addr_ready;
        logic        committed;
        logic [31:0] addr;
        logic [31:0] data;
        logic [PR_BITS-1:0]  rd_phys;
        logic [ROB_BITS-1:0] rob_idx;
        lsq_state_t state;
    } lsq_entry_t;

    lsq_entry_t lsq [LSQ_SIZE];
    logic [$clog2(LSQ_SIZE):0] head, tail;

    logic [31:0] eff_addr;
    assign eff_addr = rs1_val + imm;

    /* ---------------- FULL FLAG ---------------- */
    assign lsu_full =
        (tail[$clog2(LSQ_SIZE)] != head[$clog2(LSQ_SIZE)]) &&
        (tail[$clog2(LSQ_SIZE)-1:0] == head[$clog2(LSQ_SIZE)-1:0]);

    assign lsu_idx = tail[$clog2(LSQ_SIZE)-1:0];

    /* ---------------- SEQUENTIAL ---------------- */
    always_ff @(posedge clk or posedge rst) begin
        if (rst || flush) begin
            head <= '0;
            tail <= '0;
            for (int i=0;i<LSQ_SIZE;i++) begin
                lsq[i].valid <= 0;
                lsq[i].state <= LSQ_IDLE;
                lsq[i].committed <= 0;
            end
        end else begin

            /* ---- ALLOC ---- */
            if (lsu_alloc_en && !lsu_full) begin
                lsq[tail[$clog2(LSQ_SIZE)-1:0]] <= '{
                    valid:1,
                    is_store:lsu_is_store,
                    addr_ready:0,
                    committed:0,
                    addr:0,
                    data:0,
                    rd_phys:lsu_rd_phys,
                    rob_idx:lsu_rob_idx,
                    state:LSQ_IDLE
                };
                tail <= tail + 1;
            end

            /* ---- EXEC ADDR ---- */
            if (lsu_exec_en) begin
                lsq[lsu_exec_idx].addr       <= eff_addr;
                lsq[lsu_exec_idx].data       <= rs2_val;
                lsq[lsu_exec_idx].addr_ready <= 1'b1;
            end

            /* ---- ROB COMMIT ---- */
            if (lsu_commit_en) begin
                for (int i=0;i<LSQ_SIZE;i++) begin
                    if (lsq[i].valid &&
                        lsq[i].is_store &&
                        lsq[i].rob_idx == lsu_commit_rob_idx)
                        lsq[i].committed <= 1'b1;
                end
            end

            /* ---- LOAD RESPONSE ---- */
            if (lsq[head[$clog2(LSQ_SIZE)-1:0]].state == LSQ_WAIT_MEM &&
                dcache_hit) begin
                lsq[head[$clog2(LSQ_SIZE)-1:0]].state <= LSQ_DONE;
            end

            /* ---- RETIRE ---- */
            if (lsq[head[$clog2(LSQ_SIZE)-1:0]].valid &&
                lsq[head[$clog2(LSQ_SIZE)-1:0]].state == LSQ_DONE) begin
                lsq[head[$clog2(LSQ_SIZE)-1:0]].valid <= 0;
                head <= head + 1;
            end
        end
    end

    /* ---------------- COMBINATIONAL ---------------- */
always_comb begin
    dcache_addr  = '0;
    dcache_wdata = '0;
    dcache_re    = 1'b0;
    dcache_we    = 1'b0;

    lsu_wb_valid = 1'b0;
    lsu_wb_phys  = '0;
    lsu_wb_data  = '0;

    if (lsq[head[$clog2(LSQ_SIZE)-1:0]].valid &&
        lsq[head[$clog2(LSQ_SIZE)-1:0]].addr_ready) begin

        dcache_addr =
            lsq[head[$clog2(LSQ_SIZE)-1:0]].addr;

        if (lsq[head[$clog2(LSQ_SIZE)-1:0]].is_store) begin
            if (lsq[head[$clog2(LSQ_SIZE)-1:0]].committed) begin
                dcache_we    = 1'b1;
                dcache_wdata =
                    lsq[head[$clog2(LSQ_SIZE)-1:0]].data;
            end
        end else begin
            dcache_re = 1'b1;
            if (dcache_hit) begin
                lsu_wb_valid = 1'b1;
                lsu_wb_phys  =
                    lsq[head[$clog2(LSQ_SIZE)-1:0]].rd_phys;
                lsu_wb_data  = dcache_rdata;
            end
        end
    end
end

endmodule
