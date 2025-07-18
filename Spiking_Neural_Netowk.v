// ROM-based weight lookup table.
// Each 3-bit address maps to 3 output weights (3-bit each).

module weight_rom (
    input wire [2:0] addr,         // Address selects weight set (8 possibilities)
    output reg [2:0] w1, w2, w3    // Output weights for 3 inputs
);
    always @(*) begin
        case (addr)
            3'd0: begin w1 = 3'd2; w2 = 3'd3; w3 = 3'd1; end
            3'd1: begin w1 = 3'd4; w2 = 3'd0; w3 = 3'd5; end
            3'd2: begin w1 = 3'd6; w2 = 3'd1; w3 = 3'd2; end
            3'd3: begin w1 = 3'd7; w2 = 3'd2; w3 = 3'd0; end
            3'd4: begin w1 = 3'd1; w2 = 3'd6; w3 = 3'd3; end
            3'd5: begin w1 = 3'd3; w2 = 3'd5; w3 = 3'd2; end
            3'd6: begin w1 = 3'd0; w2 = 3'd1; w3 = 3'd7; end
            3'd7: begin w1 = 3'd2; w2 = 3'd2; w3 = 3'd2; end
            default: begin w1 = 3'd0; w2 = 3'd0; w3 = 3'd0; end
        endcase
    end
endmodule


// Spiking neuron implementing a discrete-time LIF model.

module spike_neuron (
    input wire clk,                       // Clock signal
    input wire neuron_input1,            // Input spikes from other neurons
    input wire neuron_input2,
    input wire neuron_input3,
    input wire [2:0] wght_1i,            // Corresponding synaptic weights
    input wire [2:0] wght_2i,
    input wire [2:0] wght_3i,
    output reg neuron_out                // Output spike
);
    parameter V_REST = 6;                // Resting membrane potential
    parameter V_LEAK = 1;                // Leakage per time step
    parameter K_SYN = 1;                 // Synaptic gain
    parameter V_THRESH = 14;            // Spike threshold

    reg [4:0] V_i;                       // Membrane potential (5 bits to handle overflow)

    initial begin
        V_i = V_REST;
        neuron_out = 0;
    end

    always @(posedge clk) begin
        neuron_out <= 0; // Reset output every cycle

        // Update membrane potential: weighted input sum - leak
        V_i <= V_i + K_SYN * (wght_1i * neuron_input1 + 
                              wght_2i * neuron_input2 + 
                              wght_3i * neuron_input3) - V_LEAK;

        if (V_i >= V_THRESH) begin
            V_i <= V_REST;      // Reset after spike
            neuron_out <= 1;    // Emit spike
        end else if (V_i < V_REST) begin
            V_i <= V_REST;      // Clip to resting potential if under
        end
    end
endmodule

/* 2-layer feedforward spiking neural network.
 * Layer 1 has 3 neurons (4, 5, 6) fed by external inputs (1, 2, 3)
 * Layer 2 has 2 neurons (7, 8) fed by outputs of layer 1
 * Weights for both layers are selected via weight_addr1 and weight_addr2
 */

module spiking_network (
    input wire clk,
    input wire [2:0] weight_addr1,      // ROM address for layer 1 weights
    input wire [2:0] weight_addr2,      // ROM address for layer 2 weights
    input wire neuron_1, neuron_2, neuron_3, // External input spikes
    output wire neuron_7, neuron_8      // Output layer spikes
);

    // Weights fetched from ROM for each layer
    wire [2:0] w1_layer1, w2_layer1, w3_layer1;
    wire [2:0] w1_layer2, w2_layer2, w3_layer2;

    // Instantiate ROMs to fetch weights
    weight_rom rom_layer1 (
        .addr(weight_addr1),
        .w1(w1_layer1), .w2(w2_layer1), .w3(w3_layer1)
    );

    weight_rom rom_layer2 (
        .addr(weight_addr2),
        .w1(w1_layer2), .w2(w2_layer2), .w3(w3_layer2)
    );

    // Intermediate neuron outputs (hidden layer)
    wire neuron_4, neuron_5, neuron_6;

    // Hidden layer neurons with rotated weight assignments for diversity
    spike_neuron neuron4 (
        .clk(clk),
        .neuron_input1(neuron_1),
        .neuron_input2(neuron_2),
        .neuron_input3(neuron_3),
        .wght_1i(w1_layer1),
        .wght_2i(w2_layer1),
        .wght_3i(w3_layer1),
        .neuron_out(neuron_4)
    );

    spike_neuron neuron5 (
        .clk(clk),
        .neuron_input1(neuron_1),
        .neuron_input2(neuron_2),
        .neuron_input3(neuron_3),
        .wght_1i(w2_layer1),
        .wght_2i(w3_layer1),
        .wght_3i(w1_layer1),
        .neuron_out(neuron_5)
    );

    spike_neuron neuron6 (
        .clk(clk),
        .neuron_input1(neuron_1),
        .neuron_input2(neuron_2),
        .neuron_input3(neuron_3),
        .wght_1i(w3_layer1),
        .wght_2i(w1_layer1),
        .wght_3i(w2_layer1),
        .neuron_out(neuron_6)
    );

    // Output layer neurons, again with rotated weights
    spike_neuron neuron7 (
        .clk(clk),
        .neuron_input1(neuron_4),
        .neuron_input2(neuron_5),
        .neuron_input3(neuron_6),
        .wght_1i(w1_layer2),
        .wght_2i(w2_layer2),
        .wght_3i(w3_layer2),
        .neuron_out(neuron_7)
    );

    spike_neuron neuron8 (
        .clk(clk),
        .neuron_input1(neuron_4),
        .neuron_input2(neuron_5),
        .neuron_input3(neuron_6),
        .wght_1i(w2_layer2),
        .wght_2i(w3_layer2),
        .wght_3i(w1_layer2),
        .neuron_out(neuron_8)
    );

endmodule
