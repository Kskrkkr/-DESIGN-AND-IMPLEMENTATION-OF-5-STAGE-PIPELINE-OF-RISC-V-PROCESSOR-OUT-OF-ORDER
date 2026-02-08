module memory_disambiguation #(
    parameter LSQ_SIZE = 8
)(
    input  logic [31:0] load_addr,
    
    // Search the Store Queue
    input  logic [LSQ_SIZE-1:0] sq_valid,
    input  logic [31:0] sq_addr [LSQ_SIZE-1:0],
    input  logic [31:0] sq_data [LSQ_SIZE-1:0],

    output logic        forward_hit,
    output logic [31:0] forwarded_data
);
    always_comb begin
        forward_hit = 1'b0;
        forwarded_data = 32'h0;
        
        // Search backwards from the most recent store to find a match
        for (int i = LSQ_SIZE-1; i >= 0; i--) begin
            if (sq_valid[i] && (sq_addr[i] == load_addr)) begin
                forward_hit = 1'b1;
                forwarded_data = sq_data[i];
                break; // Take the newest matching store
            end
        end
    end
endmodule