module rat #(
    parameter ARCH_REGS = 32,
    parameter PHYS_REGS = 64,
    parameter PR_BITS   = 6
)(
    input  logic               clk,
    input  logic               rst,

    // Read ports
    input  logic [4:0]         rs1_arch,
    input  logic [4:0]         rs2_arch,
    output logic [PR_BITS-1:0] rs1_phys,
    output logic [PR_BITS-1:0] rs2_phys,

    // Old mapping for ROB
    output logic [PR_BITS-1:0] old_phys,

    // Rename (write) port
    input  logic               rename_en,
    input  logic [4:0]         rd_arch,
    input  logic [PR_BITS-1:0] rd_phys
);

    logic [PR_BITS-1:0] rat_table [ARCH_REGS-1:0];
    integer i;

    /* ============================
       RAT update
       ============================ */
always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
        rat_table[0] <= 6'd0;
        for (int i = 1; i < 32; i++)
            rat_table[i] <= i;
    end else begin
        // UPDATE RAT ONLY AFTER RENAME
        if (rename_en && rd_arch != 0)
            rat_table[rd_arch] <= rd_phys;
    end
end

    /* ============================
       Combinational reads
       ============================ */
    assign rs1_phys = rat_table[rs1_arch];
    assign rs2_phys = rat_table[rs2_arch];

    /* ============================
       Old physical register (CRITICAL)
       ============================ */
    assign old_phys = (rename_en && rd_arch != 0)
                        ? rat_table[rd_arch]
                        : '0;

endmodule