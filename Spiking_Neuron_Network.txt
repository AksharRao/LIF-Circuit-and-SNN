
// Weight ROM module for LUT-based weights

module weight_rom (
    input wire [2:0] addr, // 3-bit address input for weight selection, so 8 unique addresses
    
    // Outputs for weights corresponding to the address
    output reg [2:0] w1,
    output reg [2:0] w2,
    output reg [2:0] w3
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

// A single discrete-time spiking neuron, emulating the Leaky Integrate-and-Fire (LIF) model.

module spike_neuron (
    input wire clk, // Global clock signal

    // Inputs from other neurons
    input wire neuron_input1,
    input wire neuron_input2,
    input wire neuron_input3,

    // 3-bit weights for each input
    input wire [2:0] wght_1i,
    input wire [2:0] wght_2i,
    input wire [2:0] wght_3i,

    // Spiking output of this neuron
    output reg neuron_out
);
    parameter V_REST = 6; // Resting potential of the neuron
    parameter V_LEAK = 1; // Passive leak rate
    parameter K_SYN = 1; // Synaptic gain factor
    parameter V_THRESH = 14; // Threshold potential for spiking
    
    reg [4:0] V_i; // 5 bit membrane potential
    
    initial begin
        V_i = V_REST;
        neuron_out = 0;
    end
    
    always @(posedge clk) begin
        neuron_out <= 0; // Reset unless spiking condition is met

        // Integrate inputs and apply weights
        V_i <= V_i + K_SYN * (wght_1i * neuron_input1 + wght_2i * neuron_input2 + wght_3i * neuron_input3) - V_LEAK;
        
        if (V_i >= V_THRESH) 
        begin
            V_i <= V_REST; // Reset potential after spike
            neuron_out <= 1; // Fire a spike!
        end

        else if (V_i < V_REST) 
        begin
            V_i <= V_REST;
        end
    end
endmodule

/* A 5-neuron spiking neural network with a 2-layer feedforward structure, 
where weights are selected from the module "weight_rom." */

module spiking_network (
    input wire clk,
    input wire [2:0] weight_addr1,  // Index for first layer weights
    input wire [2:0] weight_addr2, // Index for second layer weights

    // External spike inputs to the network
    input wire neuron_1,
    input wire neuron_2,
    input wire neuron_3,

    // Final Spikking Output Neurons
    output wire neuron_7,
    output wire neuron_8
);
    
    // Wires for ROM outputs
    wire [2:0] w1_layer1, w2_layer1, w3_layer1;  // First ROM outputs
    wire [2:0] w1_layer2, w2_layer2, w3_layer2;  // Second ROM outputs
    
    // ROM instances for different layers
    weight_rom rom_layer1 (
        .addr(weight_addr1),
        .w1(w1_layer1),
        .w2(w2_layer1),
        .w3(w3_layer1)
    );
    
    weight_rom rom_layer2 (
        .addr(weight_addr2),
        .w1(w1_layer2),
        .w2(w2_layer2),
        .w3(w3_layer2)
    );
    
    // Hidden Layer Neurons
    wire neuron_4, neuron_5, neuron_6;
    
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