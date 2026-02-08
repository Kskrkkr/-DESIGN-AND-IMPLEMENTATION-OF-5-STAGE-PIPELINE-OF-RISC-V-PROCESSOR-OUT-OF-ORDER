module btb #(
    parameter ENTRIES = 64
)(
    input  logic        clk,
    input  logic        rst,

    // --- PREDICTION (Frontend) ---
    input  logic [31:0] fetch_pc,
    output logic        pred_taken,
    output logic [31:0] pred_target,

    // --- UPDATE (Resolution from Execute) ---
    input  logic        update_en,
    input  logic [31:0] update_pc,
    input  logic [31:0] update_target,
    input  logic        actual_taken
);

    typedef struct packed {
        logic        valid;
        logic [19:0] tag;
        logic [31:0] target;
        logic [1:0]  state; // 2-bit saturating counter (00,01: NT | 10,11: T)
    } btb_entry_t;

    btb_entry_t btb_mem [ENTRIES-1:0];

    // Simple Indexing: uses bits [7:2] of PC for 64 entries
    logic [$clog2(ENTRIES)-1:0] f_idx, u_idx;
    assign f_idx = fetch_pc[$clog2(ENTRIES)+1:2];
    assign u_idx = update_pc[$clog2(ENTRIES)+1:2];

    // Combinational Prediction
    always_comb begin
        if (btb_mem[f_idx].valid && btb_mem[f_idx].tag == fetch_pc[31:12]) begin
            pred_taken  = btb_mem[f_idx].state[1]; // Taken if MSB is 1
            pred_target = btb_mem[f_idx].target;
        end else begin
            pred_taken  = 1'b0;
            pred_target = fetch_pc + 4;
        end
    end

    // Sequential Update
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            for (int i=0; i<ENTRIES; i++) btb_mem[i].valid <= 0;
        end else if (update_en) begin
            btb_mem[u_idx].valid  <= 1'b1;
            btb_mem[u_idx].tag    <= update_pc[31:12];
            btb_mem[u_idx].target <= update_target;
            
            // 2-bit Saturating Counter Logic
            case (btb_mem[u_idx].state)
                2'b00: btb_mem[u_idx].state <= (actual_taken) ? 2'b01 : 2'b00;
                2'b01: btb_mem[u_idx].state <= (actual_taken) ? 2'b10 : 2'b00;
                2'b10: btb_mem[u_idx].state <= (actual_taken) ? 2'b11 : 2'b01;
                2'b11: btb_mem[u_idx].state <= (actual_taken) ? 2'b11 : 2'b10;
            endcase
        end
    end
endmodule