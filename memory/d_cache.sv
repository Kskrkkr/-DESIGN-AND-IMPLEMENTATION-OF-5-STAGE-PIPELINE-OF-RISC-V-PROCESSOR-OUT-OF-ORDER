module d_cache (
    input  logic        clk,
    input  logic [31:0] addr,
    input  logic [31:0] wdata,
    input  logic        read_en,
    input  logic        write_en,

    output logic [31:0] rdata,
    output logic        hit,
    output logic        miss
);
    // Simplified Tag & Data Storage
    logic [31:0] cache_data [255:0];
    logic [21:0] cache_tags [255:0];
    logic        valid_bits [255:0];

    logic [7:0] index;
    logic [21:0] tag;

    assign index = addr[9:2];
    assign tag   = addr[31:10];

    always_comb begin
        hit  = valid_bits[index] && (cache_tags[index] == tag);
        miss = (read_en || write_en) && !hit;
        rdata = hit ? cache_data[index] : 32'h0;
    end

    always_ff @(posedge clk) begin
        if (write_en && hit) begin
            cache_data[index] <= wdata;
        end
    end
endmodule