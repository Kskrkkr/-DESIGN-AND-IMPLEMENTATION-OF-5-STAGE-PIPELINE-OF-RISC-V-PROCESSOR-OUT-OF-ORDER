`timescale 1ns/1ps

module tb_rob;

    logic clk;
    logic rst;
    logic push, pop;
    logic [5:0] dst_phys;

    // Clock
    always #5 clk = ~clk;

    rob dut (
        .clk(clk),
        .rst(rst),
        .push(push),
        .dst_phys(dst_phys),
        .pop(pop)
    );

    initial begin
        clk = 0;
        rst = 1;
        push = 0;
        pop  = 0;
        #20 rst = 0;

        // Insert instructions
        #10 push = 1; dst_phys = 6'd10;
        #10 push = 1; dst_phys = 6'd11;
        #10 push = 0;

        // Commit
        #20 pop = 1;
        #10 pop = 0;

        #100 $finish;
    end

endmodule
