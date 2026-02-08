module phys_regfile (
    input  logic        clk,
    input  logic        rst,

    input  logic        we,
    input  logic [5:0]  waddr,
    input  logic [31:0] wdata,

    input  logic [5:0]  raddr1,
    input  logic [5:0]  raddr2,
    output logic [31:0] rdata1,
    output logic [31:0] rdata2,
    output logic        valid1,
    output logic        valid2
);

    logic [31:0] regs  [0:63];
    logic        valid [0:63];

    integer i;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            for (i = 0; i < 64; i++) begin
                regs[i]  <= 32'b0;
                valid[i] <= 1'b0;
            end
            valid[0] <= 1'b1; // x0 always valid
        end else begin
            if (we && waddr != 0) begin
                regs[waddr]  <= wdata;
                valid[waddr] <= 1'b1;
            end
        end
    end

    // HARDWIRE x0 READS
    assign rdata1 = (raddr1 == 0) ? 32'b0 : regs[raddr1];
    assign rdata2 = (raddr2 == 0) ? 32'b0 : regs[raddr2];

    assign valid1 = (raddr1 == 0) ? 1'b1 : valid[raddr1];
    assign valid2 = (raddr2 == 0) ? 1'b1 : valid[raddr2];

endmodule
