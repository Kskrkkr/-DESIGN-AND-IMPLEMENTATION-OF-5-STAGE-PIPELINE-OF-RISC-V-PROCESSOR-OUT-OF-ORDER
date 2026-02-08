module fetch_queue #(
    parameter DEPTH = 8
)(
    input  logic        clk,
    input  logic        rst,
    input  logic        flush, // From Branch Mispredict

    // Push (from Fetch/I-Cache)
    input  logic        push_en,
    input  logic [31:0] instr_in,
    input  logic [31:0] pc_in,

    // Pop (to Decode/Rename)
    input  logic        pop_en,
    output logic [31:0] instr_out,
    output logic [31:0] pc_out,
    output logic        empty,
    output logic        full
);

    typedef struct packed {
        logic [31:0] instr;
        logic [31:0] pc;
    } entry_t;

    entry_t queue [DEPTH-1:0];
    logic [$clog2(DEPTH):0] head, tail, count;

    assign full  = (count == DEPTH);
    assign empty = (count == 0);

    always_ff @(posedge clk or posedge rst) begin
        if (rst || flush) begin
            head <= 0; tail <= 0; count <= 0;
        end else begin
            if (push_en && !full) begin
                queue[tail] <= '{instr_in, pc_in};
                tail        <= tail + 1;
                count       <= count + (pop_en ? 0 : 1);
            end
            if (pop_en && !empty) begin
                head  <= head + 1;
                count <= count - (push_en ? 0 : 1);
            end
        end
    end

    assign instr_out = queue[head].instr;
    assign pc_out    = queue[head].pc;
endmodule