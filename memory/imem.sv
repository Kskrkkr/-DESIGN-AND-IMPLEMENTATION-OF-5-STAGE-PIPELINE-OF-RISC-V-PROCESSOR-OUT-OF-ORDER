module imem (
    input  logic [31:0] addr,
    output logic [31:0] data
);

    // 4KB instruction memory (1024 x 32-bit)
    logic [31:0] mem [0:1023];

    initial begin
        $display("Loading IMEM from sim/test_add_word.hex");
        $readmemh("sim/test_add_word.hex", mem);
    end

    // Word-aligned, bounds-checked access
    always_comb begin
        if (addr[1:0] == 2'b00 && addr[31:2] < 1024)
            data = mem[addr[31:2]];
        else
            data = 32'h00000013; // NOP (safe default)
    end

endmodule
