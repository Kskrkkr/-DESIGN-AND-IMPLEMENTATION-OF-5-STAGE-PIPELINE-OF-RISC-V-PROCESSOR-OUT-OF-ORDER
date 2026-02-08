module id_stage (
    input  logic [31:0] inst,

    output logic [6:0]  opcode,
    output logic [4:0]  rs1,
    output logic [4:0]  rs2,
    output logic [4:0]  rd,

    output logic [31:0] imm,
    output logic        use_imm,
    output logic        is_branch,
    output logic [1:0]  br_type,
    output logic        is_load,
    output logic        is_store,
    output logic [3:0]  alu_op
);

    always_comb begin
        // -------------------------
        // SAFE DEFAULTS (NOP)
        // -------------------------
        opcode     = 7'b0;
        rs1        = 5'b0;
        rs2        = 5'b0;
        rd         = 5'b0;
        imm        = 32'b0;
        use_imm    = 1'b0;
        is_branch  = 1'b0;
        is_load    = 1'b0;
        is_store   = 1'b0;
        alu_op     = 4'b0000;
        br_type    = 2'b00;

        // -------------------------
        // BLOCK UNKNOWN INSTRUCTION
        // -------------------------
        if ($isunknown(inst)) begin
            // stay as NOP
        end else begin
            // -------------------------
            // FIELD EXTRACTION
            // -------------------------
            opcode = inst[6:0];
            rd     = inst[11:7];
            rs1    = inst[19:15];
            rs2    = inst[24:20];

            // -------------------------
            // DECODE
            // -------------------------
            case (opcode)

                // ADD / SUB
                7'b0110011: begin
                    use_imm = 1'b0;
                    alu_op  = inst[30] ? 4'b0001 : 4'b0000;
                end

                // ADDI
                7'b0010011: begin
                    use_imm = 1'b1;
                    alu_op  = 4'b0000;
                    imm     = {{20{inst[31]}}, inst[31:20]};
                end

                // LW
                7'b0000011: begin
                    use_imm = 1'b1;
                    is_load = 1'b1;
                    alu_op  = 4'b0000;
                    imm     = {{20{inst[31]}}, inst[31:20]};
                end

                // SW
                7'b0100011: begin
                    use_imm  = 1'b1;
                    is_store = 1'b1;
                    alu_op   = 4'b0000;
                    imm      = {{20{inst[31]}}, inst[31:25], inst[11:7]};
                end

                // BEQ / BNE
                7'b1100011: begin
                    is_branch = 1'b1;
                    imm = {{19{inst[31]}}, inst[31], inst[7],
                           inst[30:25], inst[11:8], 1'b0};

                    case (inst[14:12])
                        3'b000: br_type = 2'b00; // BEQ
                        3'b001: br_type = 2'b01; // BNE
                        default: br_type = 2'b00;
                    endcase
                end

                default: begin
                    // treat unknown opcode as NOP
                end
            endcase
        end
    end

endmodule
