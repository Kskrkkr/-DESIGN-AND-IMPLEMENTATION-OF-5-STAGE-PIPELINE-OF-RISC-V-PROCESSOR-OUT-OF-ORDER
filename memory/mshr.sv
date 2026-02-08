module mshr #(
    parameter MSHR_SIZE = 4,
    parameter PR_BITS = 6
)(
    input  logic        clk,
    input  logic        rst,

    // From D-Cache Miss
    input  logic        miss_occurred,
    input  logic [31:0] miss_addr,
    input  logic [PR_BITS-1:0] target_reg,

    // To Main Memory Interface
    output logic        mem_req_valid,
    output logic [31:0] mem_req_addr,

    // From Main Memory (Response)
    input  logic        mem_resp_valid,
    input  logic [31:0] mem_resp_data,

    // Wakeup to Issue Queue / ROB
    output logic        wb_valid,
    output logic [PR_BITS-1:0] wb_phys,
    output logic [31:0] wb_data
);

    typedef struct packed {
        logic valid;
        logic [31:0] addr;
        logic [PR_BITS-1:0] pr;
    } mshr_entry_t;

    mshr_entry_t entries [MSHR_SIZE-1:0];

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            for(int i=0; i<MSHR_SIZE; i++) entries[i].valid <= 0;
        end else begin
            // Register a new miss
            if (miss_occurred) begin
                for(int i=0; i<MSHR_SIZE; i++) begin
                    if (!entries[i].valid) begin
                        entries[i].valid <= 1'b1;
                        entries[i].addr  <= miss_addr;
                        entries[i].pr    <= target_reg;
                        break;
                    end
                end
            end
            
            // Clean up entry on memory response
            if (mem_resp_valid) begin
                // Simplified: assuming first entry matches
                entries[0].valid <= 1'b0;
            end
        end
    end

    // Wakeup signals for the OoO Engine
    assign wb_valid = mem_resp_valid;
    assign wb_phys  = entries[0].pr;
    assign wb_data  = mem_resp_data;
    
    assign mem_req_valid = entries[0].valid;
    assign mem_req_addr  = entries[0].addr;

endmodule