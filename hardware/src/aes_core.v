`timescale 1ns / 1ps

module aes_core (
    input  wire         clk,
    input  wire         reset_n,
    input  wire         enable,
    input  wire [127:0] key,
    input  wire [127:0] data_in,
    output reg  [127:0] data_out,
    output reg          valid_out
);

    // -----------------------------------------------------------
    // COMBINATORIAL STAGE (The Math)
    // We calculate the mixing logic continuously as wires
    // -----------------------------------------------------------
    
    // 1. Key Mixing (AddRoundKey)
    wire [127:0] round1_mix;
    assign round1_mix = data_in ^ key;

    // 2. Substitution Simulation (S-Box)
    // We calculate the twisted bits here
    wire [127:0] sbox_out;
    
    // Mixing logic (Avalanche Effect)
    assign sbox_out[127:96] = (round1_mix[127:96] << 3) ^ (round1_mix[31:0]   >> 5) ^ key[127:96];
    assign sbox_out[95:64]  = (round1_mix[95:64]  << 7) ^ (round1_mix[127:96] >> 2) ^ key[95:64];
    assign sbox_out[63:32]  = (round1_mix[63:32]  << 11)^ (round1_mix[95:64]  >> 3) ^ key[63:32];
    assign sbox_out[31:0]   = (round1_mix[31:0]   << 19)^ (round1_mix[63:32]  >> 7) ^ key[31:0];

    // -----------------------------------------------------------
    // SEQUENTIAL STAGE (The Latch)
    // We capture the result on the clock edge
    // -----------------------------------------------------------
    always @(posedge clk) begin
        if (!reset_n) begin
            data_out  <= 128'h0;
            valid_out <= 0;
        end else if (enable) begin
            // Latch the calculated value
            data_out  <= sbox_out;
            valid_out <= 1;
        end else begin
            valid_out <= 0;
        end
    end

endmodule