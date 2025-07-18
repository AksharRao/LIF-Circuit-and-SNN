// -----------------------------------------------------------------------------
// Module: lif_online_hebbian_3in
// Description:
//   A single LIF (Leaky Integrate-and-Fire) neuron with 3 binary spike inputs,
//   online Hebbian learning, and weight decay. Weights are updated in real-time
//   based on co-activity (Hebbian condition) and decay if unused.
// -----------------------------------------------------------------------------

module lif_online_hebbian_3in (
    input clk,
    input reset,
    input x0, x1, x2,                  // 3 pre-synaptic spike inputs
    output reg spike_out,              // Neuron output spike
    output reg [7:0] w0, w1, w2        // Synaptic weights (modifiable)
);

    // Parameters
    parameter V_thresh = 8'd100;       // Spike threshold
    parameter V_reset  = 8'd0;         // Membrane potential reset value after spike
    parameter leak     = 8'd2;         // Leak per time step
    parameter eta      = 8'd1;         // Hebbian learning increment
    parameter decay_shift = 3;         // Right-shift for decay ≈ division by 8
    parameter MAX_WEIGHT = 8'd255;     // Clamp upper limit for weights

    // Internal neuron state
    reg [7:0] V; // Membrane potential

    // Weighted contributions from active inputs
    wire [7:0] weighted_input0 = x0 ? w0 : 8'd0;
    wire [7:0] weighted_input1 = x1 ? w1 : 8'd0;
    wire [7:0] weighted_input2 = x2 ? w2 : 8'd0;

    // Hebbian conditions: active input AND neuron spiked
    wire hebbian_condition0 = x0 & spike_out;
    wire hebbian_condition1 = x1 & spike_out;
    wire hebbian_condition2 = x2 & spike_out;

    // Decay values: proportional to current weights
    wire [7:0] decay_value0 = w0 >> decay_shift;
    wire [7:0] decay_value1 = w1 >> decay_shift;
    wire [7:0] decay_value2 = w2 >> decay_shift;

    // Intermediate registers for updated weights
    reg [8:0] w0_add, w1_add, w2_add;  // For Hebbian increment
    reg [8:0] w0_new, w1_new, w2_new;  // After applying decay

    // -------------------------------------------------------------------------
    // LIF Neuron: integrate inputs, apply leak, check threshold
    // -------------------------------------------------------------------------
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            V <= V_reset;
            spike_out <= 0;
        end else begin
            if (spike_out) begin
                V <= V_reset; // Reset membrane after spike
            end else begin
                // Integrate weighted inputs and apply leak
                V <= V - leak + weighted_input0 + weighted_input1 + weighted_input2;
            end

            // Spike if threshold is crossed
            spike_out <= (V >= V_thresh) ? 1'b1 : 1'b0;
        end
    end

    // -------------------------------------------------------------------------
    // Hebbian Learning + Weight Decay Logic
    // -------------------------------------------------------------------------
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            // Initialize weights to small fixed value
            w0 <= 8'd10;
            w1 <= 8'd10;
            w2 <= 8'd10;
        end else begin
            // Hebbian Update: increase weight if input and output spike together
            w0_add = hebbian_condition0 ? (w0 + eta) : w0;
            w1_add = hebbian_condition1 ? (w1 + eta) : w1;
            w2_add = hebbian_condition2 ? (w2 + eta) : w2;

            // Apply decay: subtract a small portion of weight each cycle
            w0_new = (w0_add > decay_value0) ? (w0_add - decay_value0) : 0;
            w1_new = (w1_add > decay_value1) ? (w1_add - decay_value1) : 0;
            w2_new = (w2_add > decay_value2) ? (w2_add - decay_value2) : 0;

            // Clamp weights to MAX_WEIGHT limit (8-bit max)
            w0 <= (w0_new > MAX_WEIGHT) ? MAX_WEIGHT : w0_new[7:0];
            w1 <= (w1_new > MAX_WEIGHT) ? MAX_WEIGHT : w1_new[7:0];
            w2 <= (w2_new > MAX_WEIGHT) ? MAX_WEIGHT : w2_new[7:0];
        end
    end

endmodule