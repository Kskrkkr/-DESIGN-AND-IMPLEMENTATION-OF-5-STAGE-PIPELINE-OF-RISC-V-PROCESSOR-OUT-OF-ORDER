module i_cache #(
    parameter CACHE_SETS = 256, // 1KB Cache if 4-byte lines
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
)(
    input  logic        clk,
    input  logic        rst,

    // Interface to IF Stage (PC Unit)
    input  logic [31:0] addr,
    input  logic        req,
    output logic [31:0] instr_out,
    output logic        hit,
    output logic        miss,

    // Interface to Main Memory (Instruction Miss Path)
    output logic        mem_req,
    output logic [31:0] mem_addr,
    input  logic [31:0] mem_data_in,
    input  logic        mem_ready
);

    // Local Parameters for Addressing
    // [ TAG (22 bits) | INDEX (8 bits) | OFFSET (2 bits) ]
    localparam INDEX_BITS = $clog2(CACHE_SETS);
    localparam TAG_BITS   = ADDR_WIDTH - INDEX_BITS - 2;

    // Cache Storage
    logic [DATA_WIDTH-1:0] data_array [CACHE_SETS-1:0];
    logic [TAG_BITS-1:0]   tag_array  [CACHE_SETS-1:0];
    logic                  valid_bits [CACHE_SETS-1:0];

    // Address Decoding
    logic [INDEX_BITS-1:0] index;
    logic [TAG_BITS-1:0]   tag;
    assign index = addr[INDEX_BITS+1:2];
    assign tag   = addr[31:INDEX_BITS+2];

    // Hit Detection Logic
    always_comb begin
        if (req && valid_bits[index] && (tag_array[index] == tag)) begin
            hit       = 1'b1;
            miss      = 1'b0;
            instr_out = data_array[index];
        end else if (req) begin
            hit       = 1'b0;
            miss      = 1'b1;
            instr_out = 32'h00000013; // Default to NOP during miss
        end else begin
            hit       = 1'b0;
            miss      = 1'b0;
            instr_out = 32'h00000013;
        end
    end

    // Memory Request Logic (Instruction Miss Path)
    assign mem_req  = miss;
    assign mem_addr = addr;

    // Cache Refill Logic
    // When Main Memory returns data, update the cache line
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            for (int i = 0; i < CACHE_SETS; i++) begin
                valid_bits[i] <= 1'b0;
            end
        end else begin
            if (mem_ready && miss) begin
                data_array[index] <= mem_data_in;
                tag_array[index]  <= tag;
                valid_bits[index] <= 1'b1;
            end
        end
    end

endmodule