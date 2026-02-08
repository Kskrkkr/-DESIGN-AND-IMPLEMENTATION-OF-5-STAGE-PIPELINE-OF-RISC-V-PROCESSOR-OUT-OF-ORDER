module alu (
    input  logic        clk,
    input  logic        grant,
    input  logic [31:0] a,
    input  logic [31:0] b,
    input  logic [3:0]  alu_op,
    output logic [31:0] result
);

    // ALU operation
    always_comb begin
        case (alu_op)
            4'd0: result = a + b;
            4'd1: result = a - b;
            4'd2: result = a & b;
            4'd3: result = a | b;
            default: result = 32'h0;
        endcase
    end

endmodule