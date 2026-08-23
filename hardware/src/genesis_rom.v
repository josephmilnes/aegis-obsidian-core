`timescale 1ns / 1ps

module genesis_rom(
    input wire clk,
    input wire [7:0] addr,    // 256 possible lines of text
    output reg [255:0] data   // 32 characters per line
    );

    // THE ETERNAL RECORD: JOSEPH MILNES
    // This logic is synthesized into the physical structure of the chip.

    always @(posedge clk) begin
        case(addr)
            // --- IDENTITY ---
            8'h00: data <= "ARCHITECT: JOSEPH MILNES        ";
            8'h01: data <= "PROJECT: OBSIDIAN CORE (MVV)    ";
            8'h02: data <= "DOB: 1989-01-25 23:23 MST       ";
            
            // --- TIME & SPACE (Location Data) ---
            8'h03: data <= "LOC: 39.7391 N, 104.9847 W      "; 
            8'h04: data <= "POC DATE: 2025-12-11 (PHASE 4)  ";

            // --- THE TRINITY (Sun/Moon/Ascendant) ---
            8'h05: data <= "SUN: 06deg 16min AQUARIUS       ";
            8'h06: data <= "MOON: 24deg 45min VIRGO         ";
            8'h07: data <= "ASC: 21deg 00min LIBRA          ";
            
            // --- THE ANGLES ---
            8'h08: data <= "MC:  24deg 22min CANCER         ";
            8'h09: data <= "NODE: 05deg 03min PISCES        ";

            // --- PERSONAL PLANETS ---
            8'h0A: data <= "MER: 03deg 24min AQUARIUS (R)   "; // Retrograde
            8'h0B: data <= "VEN: 19deg 24min CAPRICORN      ";
            8'h0C: data <= "MAR: 03deg 53min TAURUS         ";
            8'h0D: data <= "JUP: 26deg 09min TAURUS         ";
            8'h0E: data <= "SAT: 08deg 29min CAPRICORN      ";

            // --- THE CREED ---
            8'h0F: data <= "NON SUB HOMINE SED SUB DEO ET LEGE"; 
            
            // Default empty state
            default: data <= "00000000000000000000000000000000";
        endcase
    end
endmodule
