module freelist #(
    parameter PHYS_REGS = 64,
    parameter PR_BITS   = 6
)(
    input  logic               clk,
    input  logic               rst,
    input  logic               flush,

    // Allocate
    input  logic               alloc_en,
    output logic [PR_BITS-1:0] alloc_reg,
    output logic               alloc_valid,

    // Free
    input  logic               free_en,
    input  logic [PR_BITS-1:0] free_reg
);

    logic [PR_BITS-1:0] free_q [PHYS_REGS-1:0];
    logic [PR_BITS:0] head, tail;

    /* =========================
       RESET / FLUSH
       ========================= */
    always_ff @(posedge clk or posedge rst) begin
        if (rst || flush) begin
            head <= 0;
            tail <= PHYS_REGS - 32;

            // Only P32..P63 are free
            for (int i = 0; i < PHYS_REGS-32; i++)
                free_q[i] <= i + 32;
        end else begin

            // Free on commit
            if (free_en && free_reg != 0) begin
                free_q[tail] <= free_reg;
                tail <= tail + 1;
            end

            // Consume on allocate
            if (alloc_en && alloc_valid) begin
                head <= head + 1;
            end
        end
    end

    /* =========================
       COMBINATIONAL ALLOCATION
       ========================= */
    assign alloc_valid = (head != tail);
    assign alloc_reg   = alloc_valid ? free_q[head] : '0;

endmodule
