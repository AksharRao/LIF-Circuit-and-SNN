module lif_online_hebbian_3in (
    input clk,
    input reset,
    input x0, x1, x2,                  // 3 input spikes
    output reg spike_out,               // output spike
    output reg [7:0] w0, w1, w2         // 3 synaptic weights
);

    // Parameters
    parameter V_thresh = 8'd100;
    parameter V_reset  = 8'd0;
    parameter leak     = 8'd2;
    parameter eta      = 8'd1;
    parameter decay_shift = 3;
    parameter MAX_WEIGHT = 8'd255;

    // Internal registers
    reg [7:0] V;
    wire [7:0] weighted_input0, weighted_input1, weighted_input2;
    wire hebbian_condition0, hebbian_condition1, hebbian_condition2;
    wire [7:0] decay_value0, decay_value1, decay_value2;
    reg [8:0] w0_add, w1_add, w2_add;
    reg [8:0] w0_new, w1_new, w2_new;

    assign weighted_input0 = x0 ? w0 : 8'd0;
    assign weighted_input1 = x1 ? w1 : 8'd0;
    assign weighted_input2 = x2 ? w2 : 8'd0;
    assign hebbian_condition0 = x0 & spike_out;
    assign hebbian_condition1 = x1 & spike_out;
    assign hebbian_condition2 = x2 & spike_out;
    assign decay_value0 = w0 >> decay_shift;
    assign decay_value1 = w1 >> decay_shift;
    assign decay_value2 = w2 >> decay_shift;

    // LIF Neuron: integrate + fire
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            V <= V_reset;
            spike_out <= 0;
        end else begin
            if (spike_out) begin
                V <= V_reset;
            end else begin
                V <= V - leak + weighted_input0 + weighted_input1 + weighted_input2;
            end

            if (V >= V_thresh)
                spike_out <= 1;
            else
                spike_out <= 0;
        end
    end

    // Online Hebbian Learning with Decay for each weight
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            w0 <= 8'd10;
            w1 <= 8'd10;
            w2 <= 8'd10;
        end else begin
            // Hebbian term
            w0_add = hebbian_condition0 ? (w0 + eta) : w0;
            w1_add = hebbian_condition1 ? (w1 + eta) : w1;
            w2_add = hebbian_condition2 ? (w2 + eta) : w2;

            // Decay term
            w0_new = (w0_add > decay_value0) ? (w0_add - decay_value0) : 0;
            w1_new = (w1_add > decay_value1) ? (w1_add - decay_value1) : 0;
            w2_new = (w2_add > decay_value2) ? (w2_add - decay_value2) : 0;

            // Clamp to MAX_WEIGHT
            w0 <= (w0_new > MAX_WEIGHT) ? MAX_WEIGHT : w0_new[7:0];
            w1 <= (w1_new > MAX_WEIGHT) ? MAX_WEIGHT : w1_new[7:0];
            w2 <= (w2_new > MAX_WEIGHT) ? MAX_WEIGHT : w2_new[7:0];
        end
    end

endmodule