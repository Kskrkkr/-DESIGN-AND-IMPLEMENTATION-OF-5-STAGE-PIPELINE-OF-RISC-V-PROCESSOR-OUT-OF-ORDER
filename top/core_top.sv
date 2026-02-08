module core_top #(
    parameter ROB_SIZE = 16,
    parameter ROB_BITS = $clog2(ROB_SIZE)
)(
    input logic clk,
    input logic rst
);

    /* =========================
       IF / ID
       ========================= */
    logic [31:0] pc, inst;
    logic [6:0]  opcode;
    logic [4:0]  rs1, rs2, rd;
    logic [31:0] id_imm;
    logic        id_use_imm;
    logic ex_is_branch;
    logic issue_is_branch;
    logic id_is_branch;
    logic [31:0] issue_pc;
    logic [31:0] ex_pc;
    logic [1:0] id_br_type;
    logic [1:0] issue_br_type;
    logic [1:0] ex_br_type;
    logic [31:0] pred_target;
    logic        pred_taken;

    assign pred_taken  = 1'b0;        // predict NOT taken
    assign pred_target = pc + 32'd4;


    /* =========================
       CONTROL
       ========================= */
    logic        flush;
    logic [31:0] redirect_pc;


    /* =========================
       RENAME
       ========================= */
    logic [5:0] rs1_phys, rs2_phys, rd_phys, old_phys;
    logic       alloc_valid;

    /* =========================
       RESERVATION STATION
       ========================= */
    logic        rs_issue_valid;
    logic [5:0]  issue_src1, issue_src2, issue_dst;
    logic        issue_use_imm;
    logic [31:0] issue_imm;
    logic alu_grant;
    logic [$clog2(8)-1:0] issue_idx;  // RS_SIZE = 8
    logic rs_full;
    logic instr_valid;

assign instr_valid =
    !$isunknown(inst) &&
    inst != 32'h00000013; // allow NOP explicitly


    /* =========================
       PRF
       ========================= */
    logic [31:0] prf_rdata1, prf_rdata2;
    logic        prf_we;
    logic [5:0]  prf_waddr;
    logic [31:0] prf_wdata;
    logic        prf_valid1, prf_valid2;

    /* =========================
       WRITEBACK
       ========================= */
    logic        wb_valid_r;
    logic [5:0]  wb_phys_r;
    logic [31:0] wb_data_r;

    /* =========================
       EXEC PIPELINE
       ========================= */
    logic        ex_valid;
    logic [31:0] ex_a;
    logic [31:0] ex_b;
    logic [5:0]  ex_dst;
    logic [3:0] id_alu_op;
    logic       id_is_load;
    logic       id_is_store;
    logic [31:0] imem_inst;


    /* =========================
       ROB
       ========================= */
    logic        commit_valid;
    logic [5:0]  free_phys;
    logic [4:0]  commit_rd_arch;
    logic [3:0]  rob_idx;
    logic [ROB_BITS-1:0] alloc_rob_idx;
    logic [ROB_BITS-1:0] rob_idx_ex;
    logic [ROB_BITS-1:0] issue_rob_idx;
    logic commit_en;
    logic [ROB_BITS-1:0] commit_rob_idx;

    logic br_mispredict;
    logic [31:0] br_redirect_pc;
    logic [ROB_BITS-1:0] flush_idx;

    assign flush_idx = rob_idx_ex + 1'b1;

    // RENAME → RS pipeline registers
logic        ren_valid;
logic [5:0]  ren_rs1_phys, ren_rs2_phys, ren_rd_phys;
logic        ren_use_imm;
logic [31:0] ren_imm;
logic        ren_is_branch;
logic [31:0] ren_pc;
logic [1:0]  ren_br_type;
logic [ROB_BITS-1:0] ren_rob_idx;
logic [4:0] ren_rd_arch;

    imem u_imem (
    .addr (pc),
    .data (imem_inst)
);

    /* =========================
       IF STAGE
       ========================= */
    if_stage u_if (
        .clk(clk),
        .rst(rst),
        .flush(flush),
        .redirect_pc(redirect_pc),
        .inst_in     (imem_inst),
        .pc_out(pc),
        .inst_out(inst)
    );

    // // TEMP: no branch/ROB yet
    //     assign flush        = 1'b0;
    //     assign redirect_pc  = 32'b0;
    //     // assign commit_valid   = 1'b0;
    //     // assign free_phys      = 6'b0;
    //     // assign commit_rd_arch = 5'b0;
    //     assign rob_idx        = 4'b0;

    /* =========================
       ID STAGE
       ========================= */
id_stage u_id (
    .inst(inst),

    .opcode(opcode),
    .rs1(rs1),
    .rs2(rs2),
    .rd(rd),

    .imm(id_imm),
    .use_imm(id_use_imm),
    .is_branch(id_is_branch),

    .alu_op(id_alu_op),
    .is_load(id_is_load),
    .is_store(id_is_store),
    .br_type(id_br_type)
);

    /* =========================
       FREELIST
       ========================= */
    freelist u_freelist (
        .clk(clk),
        .rst(rst),
        .flush(flush),
        .alloc_en(instr_valid && (rd != 0)),
        .alloc_reg(rd_phys),
        .alloc_valid(alloc_valid),
        .free_en(commit_valid),
        .free_reg(free_phys)
    );

    /* =========================
       RAT
       ========================= */
    rat u_rat (
        .clk(clk),
        .rst(rst || flush),
        .rs1_arch(rs1),
        .rs2_arch(rs2),
        .rs1_phys(rs1_phys),
        .rs2_phys(rs2_phys),
        .rename_en(alloc_valid),
        .rd_arch(rd),
        .rd_phys(rd_phys),
        .old_phys(old_phys)
    );

    /* =========================
       RS READY
       ========================= */
    logic src1_ready, src2_ready;
assign src1_ready =
    (rs1_phys == 0) ? 1'b1 :
    ($isunknown(prf_valid1) ? 1'b0 : prf_valid1);

assign src2_ready =
    (rs2_phys == 0) ? 1'b1 :
    ($isunknown(prf_valid2) ? 1'b0 : prf_valid2);


    // assign can_dispatch =
    //    alloc_valid &&
    //    (rd != 0) &&
    //    (rd_phys !== 'x);


    //    assign rs_ready = rs_issue_valid;

        /* =========================
       WAKEUP LOGIC (RESERVATION STATION)
       ========================= */
    // Both ALU and Memory can wake up instructions in the RS

    logic global_wb_valid;
    logic [5:0] global_wb_phys;

           logic [31:0] id_pc;

always_ff @(posedge clk or posedge rst) begin
    if (rst || flush)
        id_pc <= 32'b0;
    else
        id_pc <= pc;
end

logic [31:0] ex_imm;
always_ff @(posedge clk or posedge rst) begin
    if (rst || flush)
        ex_imm <= 32'b0;
    else if (alu_grant)
        ex_imm <= issue_imm;
end


reservation_station u_rs (
    .clk(clk),
    .rst(rst || flush),

    .dispatch_en      (rs_dispatch_en),
    .dispatch_is_branch(ren_is_branch),
    .dispatch_pc      (ren_pc),

    .src1(ren_rs1_phys),
    .src2(ren_rs2_phys),
    .dst(ren_rd_phys),
    .use_imm(ren_use_imm),
    .imm(ren_imm),
    .src1_ready       (src1_ready),
    .src2_ready       (src2_ready),

    .wb_valid         (global_wb_valid),
    .wb_phys          (global_wb_phys),

    .issue_grant      (alu_grant),
    .issue_br_type   (issue_br_type),

    .issue_valid      (rs_issue_valid),
    .issue_src1       (issue_src1),
    .issue_src2       (issue_src2),
    .issue_dst        (issue_dst),
    .issue_use_imm    (issue_use_imm),
    .issue_imm        (issue_imm),
    .issue_idx        (issue_idx),
    .issue_is_branch  (issue_is_branch),
    .issue_pc         (issue_pc),
    .issue_rob_idx    (issue_rob_idx),
    .dispatch_br_type (ren_br_type),

    .rs_full          (rs_full),
    .alloc_rob_idx    (alloc_rob_idx)
);


    /* =========================
       ISSUE LOGIC (FIXED)
       ========================= */
    issue_logic u_issue (
        .rs_issue_valid (rs_issue_valid),
        .alu_grant(alu_grant)
    );

    /* =========================
       PRF
       ========================= */
    phys_regfile u_prf (
        .clk(clk),
        .rst(rst),
        .we(prf_we),
        .waddr(prf_waddr),
        .wdata(prf_wdata),
        .raddr1(issue_src1),
        .raddr2(issue_src2),
        .rdata1(prf_rdata1),
        .rdata2(prf_rdata2),
        .valid1(prf_valid1),
        .valid2(prf_valid2)
    );

        logic [3:0] ex_alu_op;
        logic       ex_use_imm;




    /* =========================
       EX PIPELINE
       ========================= */
always_ff @(posedge clk or posedge rst) begin
    if (rst || flush) begin
        ex_valid     <= 1'b0;
        ex_a         <= 32'b0;
        ex_b         <= 32'b0;
        ex_dst       <= 6'b0;
        ex_pc        <= 32'b0;
        ex_is_branch <= 1'b0;
        ex_br_type   <= 2'b00;
        ex_alu_op    <= 4'b0000;
    end
    else if (alu_grant && rs_issue_valid) begin
        ex_valid     <= 1'b1;
        ex_a         <= prf_rdata1;
        ex_b         <= issue_use_imm ? issue_imm :
                        (issue_src2 == 0 ? 32'b0 : prf_rdata2);
        ex_dst       <= issue_dst;
        ex_pc        <= issue_pc;
        ex_is_branch <= issue_is_branch;
        ex_br_type   <= issue_br_type;
        ex_alu_op    <= id_alu_op;  
    end
    else begin
        ex_valid <= 1'b0;
    end
end




always_ff @(posedge clk or posedge rst) begin
    if (rst || flush)
        rob_idx_ex <= '0;
    else if (ex_valid)
        rob_idx_ex <= issue_rob_idx;
    else
        rob_idx_ex <= rob_idx_ex; // explicit hold 
end

wire [31:0] branch_src2 = ex_b;

always_ff @(posedge clk or posedge rst) begin
    if (rst || flush) begin
        ren_valid    <= 1'b0;
        ren_rd_arch  <= 5'd0;
        ren_rs1_phys <= 6'd0;
        ren_rs2_phys <= 6'd0;
        ren_rd_phys  <= 6'd0;
        ren_use_imm  <= 1'b0;
        ren_imm      <= 32'd0;
        ren_is_branch<= 1'b0;
        ren_pc       <= 32'd0;
        ren_br_type  <= 2'b00;
        ren_rob_idx  <= '0;
    end else if (instr_valid) begin
        ren_valid    <= alloc_valid && (rd != 0);
        ren_rd_arch  <= rd;
        ren_rs1_phys <= rs1_phys;
        ren_rs2_phys <= rs2_phys;
        ren_rd_phys  <= rd_phys;
        ren_use_imm  <= id_use_imm;
        ren_imm      <= id_imm;
        ren_is_branch<= id_is_branch;
        ren_pc       <= pc;
        ren_br_type  <= id_br_type;
        ren_rob_idx  <= alloc_rob_idx;
    end else begin
        ren_valid <= 1'b0;
        ren_is_branch <= 1'b0;
    end
end


branch_unit u_branch (
    .br_type      (ex_br_type),   
    .src1         (ex_a),
    .src2         (ex_b),
    .br_pc        (ex_pc),
    .imm          (ex_imm),

    .pred_taken   (pred_taken),
    .pred_target  (pred_target),

    .mispredict   (br_mispredict),
    .redirect_pc  (br_redirect_pc),
    .actual_taken (),
    .actual_target()
);


assign flush =
    ex_valid &&
    ex_is_branch &&
    !($isunknown(br_mispredict)) &&
    br_mispredict;
assign redirect_pc = br_redirect_pc;


/* =========================
       MEMORY SYSTEM SIGNALS
       ========================= */
    logic        mem_is_load, mem_is_store;
    logic [$clog2(8)-1:0] lsu_idx;
    logic        mem_lsq_full;
    logic lsq_commit_en;
    logic [31:0] main_mem_addr, main_mem_data_in;
    logic        main_mem_req, main_mem_ready;
    
    logic        mem_wb_valid;
    logic [5:0]  mem_wb_phys;
    logic [31:0] mem_wb_data;

    assign lsq_commit_en = commit_en && mem_is_store;

    /* =========================
       ROB SIGNALS
       ========================= */
    logic        rob_full;

    /* =========================
       DECODE EXTENSION (For Memory)
       ========================= */

assign mem_is_load  = (opcode == 7'b0000011); // LW
assign mem_is_store = (opcode == 7'b0100011); // SW



/* =====================================================
       REORDER BUFFER (ROB) 
       ===================================================== */
    rob u_rob (
        .clk            (clk),
        .rst            (rst),
        .flush(flush),
        .flush_idx(flush_idx),
        // Allocation (Dispatch)
        .alloc_en       (rs_dispatch_en),
        .rd_arch        (ren_rd_arch),
        .rd_phys        (ren_rd_phys),
        .old_phys       (old_phys),
        .alloc_idx      (alloc_rob_idx), // Port connection #7
        // Writeback (ALU result)
        .wb_en          (wb_valid_r),    // Port connection #8
        .wb_idx         (rob_idx_ex),    // Port connection #9 
        // Commit (Retirement)
        .commit_valid   (commit_valid),
        .commit_rd_arch (commit_rd_arch),
        .commit_idx(commit_rob_idx),
        .free_phys      (free_phys)     // Port connection #12
    );

    assign commit_en      = commit_valid;


    /* =========================
       MEMORY SYSTEM (LSU + D-CACHE + MSHR)
       ========================= */
memory_system u_mem_system (
    .clk(clk),
    .rst(rst),

    .mem_alloc_en(rs_dispatch_en && (mem_is_load || mem_is_store)),
    .mem_is_store(mem_is_store),
    .mem_rd_phys(ren_rd_phys),
    .mem_rob_idx(alloc_rob_idx),
    .mem_lsq_full(mem_lsq_full),
    .flush(flush),

    .mem_exec_en (ex_valid && (mem_is_load || mem_is_store)),
    .mem_exec_idx(issue_idx),
    .rs1_val(ex_a),
    .imm(issue_imm),
    .rs2_val(ex_b),

    .main_mem_addr(main_mem_addr),
    .main_mem_req(main_mem_req),
    .main_mem_data_in(main_mem_data_in),
    .main_mem_ready(main_mem_ready),

    .wb_valid(mem_wb_valid),
    .wb_phys(mem_wb_phys),
    .mem_commit_en      (lsq_commit_en),
    .mem_commit_rob_idx (commit_rob_idx),
    .wb_data(mem_wb_data)
);

assign rs_dispatch_en =
    ren_valid &&
    !rs_full;

/* =====================================================
   UNIFIED WRITEBACK ARBITRATION
   ===================================================== */
always_comb begin
    if (mem_wb_valid) begin
        // Path from Memory (D-Cache / MSHR)
        prf_we    = 1'b1;
        prf_waddr = mem_wb_phys;
        prf_wdata = mem_wb_data;
    end else if (wb_valid_r) begin
        // Path from ALU
        prf_we    = (wb_phys_r != 0); 
        prf_waddr = wb_phys_r;
        prf_wdata = wb_data_r;
    end else begin
        // No result this cycle
        prf_we    = 1'b0;
        prf_waddr = '0;
        prf_wdata = '0;
    end
end

logic [31:0] issue_a, issue_b;

always_ff @(posedge clk) begin
    if (alu_grant) begin
        issue_a <= prf_rdata1;
        issue_b <= issue_use_imm ? issue_imm : prf_rdata2;
    end
end

    // Update RS wakeup connection
    // (Inside u_rs instantiation, change wb_valid/phys to global_wb_valid/phys)

    /* =========================
       MAIN MEMORY (SIMULATED)
       ========================= */
    // This represents the blue/gray blocks at the bottom of the diagram
    always_ff @(posedge clk) begin
        if (main_mem_req) begin
            main_mem_ready   <= 1'b1;
            main_mem_data_in <= 32'hDEADBEEF; // Dummy RAM data
        end else begin
            main_mem_ready   <= 1'b0;
        end
    end

    assign global_wb_valid = wb_valid_r || mem_wb_valid;
    assign global_wb_phys  = mem_wb_valid ? mem_wb_phys : wb_phys_r;

    /* =========================
       ALU
       ========================= */
    logic [31:0] alu_out;
    alu u_alu (
        .clk(clk),
        .grant(ex_valid),
        .a(ex_a),
        .b(ex_b),
        .alu_op(ex_alu_op),
        .result(alu_out)
    );

    /* =========================
       WRITEBACK
       ========================= */
always_ff @(posedge clk or posedge rst) begin
    if (rst || flush) begin
        wb_valid_r <= 1'b0;
        wb_phys_r  <= '0;
        wb_data_r  <= '0;
    end else if (ex_valid) begin
        wb_valid_r <= (ex_dst != 0);
        wb_phys_r  <= ex_dst;
        wb_data_r  <= alu_out;
    end else begin
        wb_valid_r <= 1'b0;
    end
end

// assign prf_we    = wb_valid_r && (wb_phys_r != 0);
// assign prf_waddr = wb_phys_r;
// assign prf_wdata = wb_data_r;

always_ff @(posedge clk) begin
    if (rs_issue_valid && alu_grant) begin
        $display("[ISSUE] src1=P%0d src2=P%0d dst=P%0d",
                 issue_src1, issue_src2, issue_dst);
    end
if (ex_valid && alu_grant) begin
    $display("[EX] A=%0d B=%0d dst=P%0d result=%0d",
             ex_a, ex_b, ex_dst, alu_out);
end
end

always_ff @(posedge clk) begin
    if (rs_dispatch_en) begin
        $display("[DISPATCH] rd=%0d rd_phys=%0d", ren_rd_arch, ren_rd_phys);
    end
end



endmodule