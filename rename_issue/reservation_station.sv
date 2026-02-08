module reservation_station #(
    parameter RS_SIZE = 8,
    parameter PR_BITS = 6,
    parameter ROB_SIZE = 16,
    parameter ROB_BITS = $clog2(ROB_SIZE)
)(
    input  logic clk,
    input  logic rst,

    // =========================
    // DISPATCH
    // =========================
    input  logic                  dispatch_en,
    input  logic [PR_BITS-1:0]    src1,
    input  logic [PR_BITS-1:0]    src2,
    input  logic [PR_BITS-1:0]    dst,
    input  logic                  src1_ready,
    input  logic                  src2_ready,
    input  logic                  use_imm,
    input  logic [31:0]           imm,
    input  logic [ROB_BITS-1:0]   alloc_rob_idx,
    input  logic                  dispatch_is_branch,
    input  logic [31:0]           dispatch_pc,
    input logic [1:0] dispatch_br_type,

    // =========================
    // WAKEUP
    // =========================
    input  logic                  wb_valid,
    input  logic [PR_BITS-1:0]    wb_phys,

    // =========================
    // ISSUE HANDSHAKE
    // =========================
    input  logic                  issue_grant,

    // =========================
    // ISSUE OUTPUTS
    // =========================
    output logic [1:0] issue_br_type,
    output logic                  issue_valid,
    output logic [PR_BITS-1:0]    issue_src1,
    output logic [PR_BITS-1:0]    issue_src2,
    output logic [PR_BITS-1:0]    issue_dst,
    output logic                  issue_use_imm,
    output logic [31:0]           issue_imm,
    output logic                  issue_is_branch,
    output logic [31:0]           issue_pc,
    output logic [ROB_BITS-1:0]   issue_rob_idx,
    output logic [$clog2(RS_SIZE)-1:0] issue_idx,
    output logic                  rs_full
);

    // =========================
    // RS ENTRY
    // =========================
    typedef struct packed {
        logic                  valid;
        logic                  rdy1;
        logic                  rdy2;
        logic [PR_BITS-1:0]    s1;
        logic [PR_BITS-1:0]    s2;
        logic [PR_BITS-1:0]    d;
        logic                  use_imm;
        logic [31:0]           imm;
        logic [ROB_BITS-1:0]   rob_idx;
        logic                  is_branch;
        logic [31:0]           pc;
        logic [1:0]  br_type;
    } rs_entry_t;

    rs_entry_t rs[RS_SIZE];

    // =====================================================
    // SEQUENTIAL: reset, wakeup, dispatch, issue-clear
    // =====================================================
always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
        for (int i = 0; i < RS_SIZE; i++) begin
            rs[i] <= '0;
        end
    end else begin

        // WAKEUP
        if (wb_valid) begin
            for (int i = 0; i < RS_SIZE; i++) begin
                if (rs[i].valid) begin
                    if (rs[i].s1 == wb_phys && rs[i].s1 != 0)
                        rs[i].rdy1 <= 1'b1;
                    if (rs[i].s2 == wb_phys && rs[i].s2 != 0)
                        rs[i].rdy2 <= 1'b1;
                end
            end
        end

// DISPATCH
if (dispatch_en && dst != 0) begin
    for (int i = 0; i < RS_SIZE; i++) begin
        if (!rs[i].valid) begin
            rs[i].valid     <= 1'b1;
            rs[i].rdy1      <= src1_ready || (src1 == 0);
            rs[i].rdy2      <= src2_ready || (src2 == 0);
            rs[i].s1        <= src1;
            rs[i].s2        <= src2;
            rs[i].d         <= dst;
            rs[i].use_imm   <= use_imm;
            rs[i].imm       <= imm;
            rs[i].rob_idx   <= alloc_rob_idx;
            rs[i].is_branch <= dispatch_is_branch;
            rs[i].pc        <= dispatch_pc;
            rs[i].br_type   <= dispatch_br_type;
            break;
        end
    end
end

        // ISSUE CLEAR
        if (issue_valid && issue_grant) begin
            rs[issue_idx].valid <= 1'b0;
        end
    end
end

    // =====================================================
    // COMBINATIONAL: issue select + rs_full
    // =====================================================
always_comb begin
    issue_valid      = 1'b0;
    issue_idx        = '0;
    issue_src1       = '0;
    issue_src2       = '0;
    issue_dst        = '0;
    issue_use_imm    = 1'b0;
    issue_imm        = '0;
    issue_pc         = '0;
    issue_rob_idx    = '0;
    issue_is_branch  = 1'b0;
    issue_br_type    = 2'b00;

    rs_full = 1'b1;

    for (int i = 0; i < RS_SIZE; i++) begin
        if (!rs[i].valid)
            rs_full = 1'b0;

        if (!issue_valid &&
            rs[i].valid &&
            rs[i].rdy1 &&
            rs[i].rdy2) begin

            issue_valid     = 1'b1;
            issue_idx       = i;
            issue_src1      = rs[i].s1;
            issue_src2      = rs[i].s2;
            issue_dst       = rs[i].d;
            issue_use_imm   = rs[i].use_imm;
            issue_imm       = rs[i].imm;
            issue_pc        = rs[i].pc;
            issue_rob_idx   = rs[i].rob_idx;
            issue_is_branch = rs[i].is_branch;
            issue_br_type   = rs[i].br_type;
        end
    end
end

endmodule
