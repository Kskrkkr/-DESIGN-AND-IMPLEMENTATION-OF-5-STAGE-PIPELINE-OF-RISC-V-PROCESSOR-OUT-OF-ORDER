module if_stage (
    input  logic        clk,
    input  logic        rst,
    input  logic        flush,
    input  logic [31:0] redirect_pc,
    input  logic [31:0] inst_in,
    output logic [31:0] pc_out,
    output logic [31:0] inst_out
);

always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
        pc_out   <= 32'b0;
        inst_out <= 32'b0;
    end else if (flush) begin
        pc_out   <= redirect_pc;
        inst_out <= inst_in;
    end else begin
        pc_out   <= pc_out + 32'd4;
        inst_out <= inst_in;
    end
end

endmodule
