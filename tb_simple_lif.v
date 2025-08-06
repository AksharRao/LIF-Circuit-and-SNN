`timescale 1ns / 1ps

module tb_LIF_Neuron;

    // Inputs
    reg clk = 0;
    reg reset;
    reg [7:0] input_current;

    // Output
    wire spike;

    // Instantiate DUT
    LIF_Neuron uut (
        .clk(clk),
        .reset(reset),
        .input_current(input_current),
        .spike(spike)
    );

    // Clock generation (10ns period)
    always #5 clk = ~clk;

    integer i;
    integer seed = 42;

    initial begin
        reset = 1;
        input_current = 0;

        #20 reset = 0;

        // Run for 100 clock cycles
        for (i = 0; i < 100; i = i + 1) begin
            @(posedge clk);
            input_current = $random(seed) % 51;
            $display("Time: %0t | Input: %d | Spike: %b", $time, input_current, spike);
        end

        $finish;
    end
endmodule



