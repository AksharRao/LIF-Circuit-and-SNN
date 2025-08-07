// -----------------------------------------------------------------------------
// Module: online_hebbian
// Description:
//   A single LIF (Leaky Integrate-and-Fire) neuron with 3 binary spike inputs,
//   online Hebbian learning, and weight decay. Weights are updated in real-time
//   based on co-activity (Hebbian condition) and decay if unused.
//
// -----------------------------------------------------------------------------

module online_hebbian (
    input clk,
    input reset,
    input x0, x1, x2,                  // 3 pre-synaptic spike inputs
    output reg spike_out,              // Neuron output spike
    output reg [7:0] w0, w1, w2        // Synaptic weights (modifiable)
);

    // Parameters (adjusted bit-widths for V and related values)
    parameter V_thresh = 10'd100;      // Spike threshold (10-bit)
    parameter V_reset  = 10'd0;        // Membrane potential reset value after spike (10-bit)
    parameter leak     = 10'd2;        // Leak per time step (10-bit)
    parameter eta      = 8'd1;         // Hebbian learning increment (8-bit, for weights)
    parameter decay_shift = 3;         // Right-shift for decay ≈ division by 8
    parameter MAX_WEIGHT = 8'd255;     // Clamp upper limit for weights (8-bit)

    // Internal neuron state (increased to 10 bits to prevent overflow)
    reg [9:0] V; // Membrane potential

    // Weighted contributions from active inputs (increased to 10 bits to prevent overflow)
    // Max wX is 255. Input is 1-bit. Max weighted_input is 255.
    // However, when summing multiple weighted_inputs, the intermediate sum can exceed 8 bits.
    // For V to correctly sum these, they must be extended.
    wire [9:0] weighted_input0 = x0 ? {2'b00, w0} : 10'd0; // Extend w0 to 10 bits
    wire [9:0] weighted_input1 = x1 ? {2'b00, w1} : 10'd0; // Extend w1 to 10 bits
    wire [9:0] weighted_input2 = x2 ? {2'b00, w2} : 10'd0; // Extend w2 to 10 bits

    // Hebbian conditions: active input AND neuron spiked
    wire hebbian_condition0 = x0 & spike_out;
    wire hebbian_condition1 = x1 & spike_out;
    wire hebbian_condition2 = x2 & spike_out;

    // Decay values: proportional to current weights
    wire [7:0] decay_value0 = w0 >> decay_shift;
    wire [7:0] decay_value1 = w1 >> decay_shift;
    wire [7:0] decay_value2 = w2 >> decay_shift;

    // Intermediate registers for updated weights (9 bits for wX + eta = 255 + 1 = 256)
    reg [8:0] w0_add, w1_add, w2_add;  // For Hebbian increment
    reg [8:0] w0_new, w1_new, w2_new;  // After applying decay

    // -------------------------------------------------------------------------
    // LIF Neuron: integrate inputs, apply leak, check threshold
    // -------------------------------------------------------------------------
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            V <= V_reset;      // Initialize membrane potential on reset
            spike_out <= 1'b0; // Initialize spike output on reset
        end else begin
            // If the neuron spiked in the previous cycle, reset membrane potential
            if (spike_out) begin
                V <= V_reset;
            end else begin
                // Integrate weighted inputs and apply leak
                // Ensure arithmetic is performed with sufficient bit-width
                V <= V - leak + weighted_input0 + weighted_input1 + weighted_input2;
            end

            // Spike if threshold is crossed (combinational check based on updated V)
            // Note: spike_out is updated based on V's value *after* integration/reset for this cycle.
            spike_out <= (V >= V_thresh) ? 1'b1 : 1'b0;
        end
    end

    // -------------------------------------------------------------------------
    // Hebbian Learning + Weight Decay Logic
    // -------------------------------------------------------------------------
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            // Initialize weights to a small fixed value on reset
            w0 <= 8'd10;
            w1 <= 8'd10;
            w2 <= 8'd10;
        end else begin
            // Hebbian Update: increase weight if input and output spike together
            // w0_add is 9 bits, correctly handling w0 + eta (255 + 1 = 256)
            w0_add = hebbian_condition0 ? (w0 + eta) : w0;
            w1_add = hebbian_condition1 ? (w1 + eta) : w1;
            w2_add = hebbian_condition2 ? (w2 + eta) : w2;

            // Apply decay: subtract a small portion of weight each cycle
            // w0_new is 9 bits, correctly handling subtraction
            w0_new = (w0_add > decay_value0) ? (w0_add - decay_value0) : 9'd0; // Ensure 9-bit 0
            w1_new = (w1_add > decay_value1) ? (w1_add - decay_value1) : 9'd0;
            w2_new = (w2_add > decay_value2) ? (w2_add - decay_value2) : 9'd0;

            // Clamp weights to MAX_WEIGHT limit (8-bit max)
            // The result is truncated back to 8 bits for the output weights.
            w0 <= (w0_new > MAX_WEIGHT) ? MAX_WEIGHT : w0_new[7:0];
            w1 <= (w1_new > MAX_WEIGHT) ? MAX_WEIGHT : w1_new[7:0];
            w2 <= (w2_new > MAX_WEIGHT) ? MAX_WEIGHT : w2_new[7:0];
        end
    end

endmodule