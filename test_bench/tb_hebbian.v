`timescale 1ns / 1ps

// Testbench for lif_online_hebbian_3in module

module tb_lif_online_hebbian_3in;

    // Testbench parameters
    parameter CLK_PERIOD = 10; // 10ns period = 100MHz clock
    parameter SIM_TIME   = 25000; // 25us simulation

    // Inputs to DUT
    reg clk;
    reg reset;
    reg x0, x1, x2;

    // Outputs from DUT
    wire spike_out;
    wire [7:0] w0, w1, w2;

    // Internal signals for monitoring
    wire [9:0] V_monitor;

    // Instantiate DUT
    lif_online_hebbian_3in uut (
        .clk(clk),
        .reset(reset),
        .x0(x0),
        .x1(x1),
        .x2(x2),
        .spike_out(spike_out),
        .w0(w0),
        .w1(w1),
        .w2(w2)
    );

    // Monitor membrane potential
    assign V_monitor = uut.V;

    // Clock generation
    initial begin
        clk = 1'b0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    // Task for input stimulus
    task apply_inputs;
        input bit in0, in1, in2;
        input integer cycles;
        begin
            x0 = in0;
            x1 = in1;
            x2 = in2;
            #(CLK_PERIOD * cycles);
        end
    endtask

    // Main stimulus
    initial begin
        // VCD dump for waveform viewing
        $dumpfile("tb_hebbian_lif.vcd");
        $dumpvars(0, tb_lif_online_hebbian_3in);

        // Initialization and Reset
        reset = 1'b1;
        x0 = 1'b0; x1 = 1'b0; x2 = 1'b0;
        #(CLK_PERIOD * 5);
        reset = 1'b0;
        #(CLK_PERIOD * 10);

        // Display header
        $display("-----------------------------------------------------------------------");
        $display("Simulation Start: lif_online_hebbian_3in Testbench");
        $display("Parameters: V_thresh=%0d, V_reset=%0d, leak=%0d, eta=%0d, decay_shift=%0d, MAX_WEIGHT=%0d",
                 uut.V_thresh, uut.V_reset, uut.leak, uut.eta, uut.decay_shift, uut.MAX_WEIGHT);
        $display("-----------------------------------------------------------------------");
        $display("Time\tX0 X1 X2\tMembrane Pot.\tSpike\tW0\tW1\tW2");
        $monitor("%0t\t%b %b %b\t%d\t\t%d\t%d\t%d\t%d",
                 $time, x0, x1, x2, V_monitor, spike_out, w0, w1, w2);
        $display("-----------------------------------------------------------------------");

        // Scenario 1: No input spikes
        $display("\n--- Scenario 1: No input (observe initial weights and decay) ---");
        apply_inputs(1'b0, 1'b0, 1'b0, 100);

        // Scenario 2: Constant x0 input
        $display("\n--- Scenario 2: Constant x0 input (w0 should increase) ---");
        apply_inputs(1'b1, 1'b0, 1'b0, 200);

        // Scenario 3: Constant x1 input
        $display("\n--- Scenario 3: Constant x1 input (w1 should increase) ---");
        apply_inputs(1'b0, 1'b1, 1'b0, 200);

        // Scenario 4: Constant x2 input
        $display("\n--- Scenario 4: Constant x2 input (w2 should increase) ---");
        apply_inputs(1'b0, 1'b0, 1'b1, 200);

        // Scenario 5: All inputs high
        $display("\n--- Scenario 5: All inputs high (all weights should increase) ---");
        apply_inputs(1'b1, 1'b1, 1'b1, 200);

        // Scenario 6: Alternating inputs and decay
        $display("\n--- Scenario 6: Alternating inputs and decay ---");
        repeat (3) begin
            apply_inputs(1'b1, 1'b0, 1'b0, 50);
            apply_inputs(1'b0, 1'b0, 1'b0, 50);
            apply_inputs(1'b0, 1'b1, 1'b0, 50);
            apply_inputs(1'b0, 1'b0, 1'b0, 50);
            apply_inputs(1'b0, 1'b0, 1'b1, 50);
            apply_inputs(1'b0, 1'b0, 1'b0, 50);
        end

        // Scenario 7: Test weight clamping
        $display("\n--- Scenario 7: Test weight clamping (driving w0 to MAX_WEIGHT) ---");
        apply_inputs(1'b1, 1'b0, 1'b0, 500);

        // Scenario 8: Patterned input
        $display("\n--- Scenario 8: Patterned input (x0, x1 together, then x2) ---");
        apply_inputs(1'b1, 1'b1, 1'b0, 100);
        apply_inputs(1'b0, 1'b0, 1'b1, 50);
        apply_inputs(1'b1, 1'b0, 1'b1, 100);
        apply_inputs(1'b0, 1'b0, 1'b0, 100);

        // Scenario 9: Randomized input spikes
        $display("\n--- Scenario 9: Randomized input spikes ---");
        repeat (500) begin
            apply_inputs($random % 2, $random % 2, $random % 2, 1);
        end

        // End simulation
        $display("\n-----------------------------------------------------------------------");
        $display("Simulation End");
        $finish;
    end

endmodule