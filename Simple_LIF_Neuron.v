// -----------------------------------------------------------------------------
// Module: LIF_Neuron
// Description:
//    Leaky Integrate-and-Fire (LIF) neuron model implemented in Verilog,
//    with an added refractory period to mimic biological neuron behavior.
// -----------------------------------------------------------------------------

module LIF_Neuron (
    input clk,
    input reset,
    input [7:0] input_current,
    output reg spike
);
    reg [7:0] membrane_potential;

    // Tunable parameters
    parameter THRESHOLD = 8'd128;      // Firing threshold
    parameter LEAK = 8'd1;             // Leakage per cycle
    parameter REFRACTORY_CYCLES = 3;   // Silent period after spike

    // Using 3 bits for the refractory counter to support up to 7 cycles,
    // ensuring compatibility with Xilinx ISE and avoiding truncation.
    reg [2:0] refractory_counter;

    wire in_refractory = (refractory_counter != 0);

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            membrane_potential <= 8'd0;
            spike <= 1'b0;
            refractory_counter <= 3'd0;
        end else begin
            if (in_refractory) begin
                spike <= 1'b0;
                refractory_counter <= refractory_counter - 1;
            end else if (membrane_potential >= THRESHOLD) begin
                spike <= 1'b1;
                membrane_potential <= 8'd0;
                refractory_counter <= REFRACTORY_CYCLES;
            end else begin
                spike <= 1'b0;
                if (membrane_potential > LEAK)
                    membrane_potential <= membrane_potential - LEAK + input_current;
                else
                    membrane_potential <= input_current;
            end
        end
    end
endmodule



