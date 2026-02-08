module branch_unit (
    input  logic [1:0]  br_type,      // 00=BEQ, 01=BNE, 10=BLT, 11=BGE
    input  logic [31:0] src1,
    input  logic [31:0] src2,
    input  logic [31:0] br_pc,
    input  logic [31:0] imm,

    // Prediction
    input  logic        pred_taken,
    input  logic [31:0] pred_target,

    // Outputs
    output logic        mispredict,
    output logic [31:0] redirect_pc,
    output logic        actual_taken,
    output logic [31:0] actual_target
);

    // Branch target
    assign actual_target = br_pc + imm;

    // Branch condition
    always_comb begin
        case (br_type)
            2'b00: actual_taken = (src1 == src2);                  // BEQ
            2'b01: actual_taken = (src1 != src2);                  // BNE
            2'b10: actual_taken = ($signed(src1) < $signed(src2)); // BLT
            2'b11: actual_taken = ($signed(src1) >= $signed(src2));// BGE
            default: actual_taken = 1'b0;
        endcase
    end

    // Mispredict logic
    always_comb begin
        mispredict  = (actual_taken != pred_taken) ||
                       (actual_taken && (pred_target != actual_target));

        redirect_pc = actual_taken ? actual_target : (br_pc + 4);
    end

endmodule
