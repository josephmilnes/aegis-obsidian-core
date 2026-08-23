`timescale 1ns / 1ps

module aegis_vault_controller # (
    parameter integer C_DATA_WIDTH = 128,
    parameter integer C_S_AXI_DATA_WIDTH = 32,
    parameter integer C_S_AXI_ADDR_WIDTH = 5
) (
    // CLOCK & RESET
    input wire  clk,
    input wire  reset_n,
    
    // *** TAMPER SENSOR (Wire Mesh) ***
    // 1 = Secure. 0 = Breached (Kill Switch).
    input wire  tamper_mesh_sense,

    // DATA STREAM (AXI4-Stream)
    input  wire [C_DATA_WIDTH-1:0]  s_axis_tdata,
    input  wire                     s_axis_tvalid,
    output wire                     s_axis_tready,
    input  wire                     s_axis_tlast,
    input  wire [C_DATA_WIDTH/8-1:0] s_axis_tkeep,

    output reg  [C_DATA_WIDTH-1:0]  m_axis_tdata,
    output reg                      m_axis_tvalid,
    input  wire                     m_axis_tready,
    output reg                      m_axis_tlast,
    output reg  [C_DATA_WIDTH/8-1:0] m_axis_tkeep,

    // CONTROL INTERFACE (AXI4-Lite)
    input wire [C_S_AXI_ADDR_WIDTH-1 : 0] s_axi_awaddr,
    input wire  s_axi_awvalid,
    output wire s_axi_awready,
    input wire [C_S_AXI_DATA_WIDTH-1 : 0] s_axi_wdata,
    input wire [C_S_AXI_DATA_WIDTH/8-1 : 0] s_axi_wstrb,
    input wire  s_axi_wvalid,
    output wire s_axi_wready,
    output wire [1 : 0] s_axi_bresp,
    output wire s_axi_bvalid,
    input wire  s_axi_bready,
    input wire [C_S_AXI_ADDR_WIDTH-1 : 0] s_axi_araddr,
    input wire  s_axi_arvalid,
    output wire s_axi_arready,
    output wire [C_S_AXI_DATA_WIDTH-1 : 0] s_axi_rdata,
    output wire [1 : 0] s_axi_rresp,
    output wire s_axi_rvalid,
    input wire  s_axi_rready
);

    // =====================================================================
    // 1. REGISTER BANK (AXI-LITE + TAMPER LOGIC)
    // =====================================================================
    // These registers hold the Bio-Hash Key and Enable bit.
    // They are the "Volatile SRAM".
    reg [31:0] slv_reg0; // Key Part 0 (LSB)
    reg [31:0] slv_reg1; // Key Part 1
    reg [31:0] slv_reg2; // Key Part 2
    reg [31:0] slv_reg3; // Key Part 3 (MSB)
    reg [31:0] slv_reg4; // Control Register (Bit 0 = Enable)

    // AXI Internal Signals
    reg axi_awready, axi_wready, axi_bvalid, axi_arready, axi_rvalid;
    reg [31:0] axi_rdata;

    // AXI Assignments
    assign s_axi_awready = axi_awready;
    assign s_axi_wready  = axi_wready;
    assign s_axi_bresp   = 2'b00; // OKAY
    assign s_axi_bvalid  = axi_bvalid;
    assign s_axi_arready = axi_arready;
    assign s_axi_rdata   = axi_rdata;
    assign s_axi_rresp   = 2'b00; // OKAY
    assign s_axi_rvalid  = axi_rvalid;

    // ---------------------------------------------------------------------
    // MERGED LOGIC: CPU WRITE + TAMPER KILL SWITCH
    // ---------------------------------------------------------------------
    // This block handles the CPU writing keys, BUT if tamper_mesh_sense
    // goes LOW (0), it overrides everything and zeroes the registers instantly.
    
    always @(posedge clk or negedge reset_n or negedge tamper_mesh_sense) begin
        // PRIORITY 1: TAMPER EVENT (Asynchronous Kill)
        // If wire mesh is cut, keys evaporate immediately.
        if (!tamper_mesh_sense) begin
            axi_awready <= 0; axi_wready <= 0; axi_bvalid <= 0;
            slv_reg0 <= 0; // DESTROY KEY
            slv_reg1 <= 0; // DESTROY KEY
            slv_reg2 <= 0; // DESTROY KEY
            slv_reg3 <= 0; // DESTROY KEY
            slv_reg4 <= 0; // DISABLE ENGINE
        end
        
        // PRIORITY 2: SYSTEM RESET (Normal Reboot)
        else if (!reset_n) begin
            axi_awready <= 0; axi_wready <= 0; axi_bvalid <= 0;
            slv_reg0 <= 0; slv_reg1 <= 0; slv_reg2 <= 0; slv_reg3 <= 0; slv_reg4 <= 0;
        end
        
        // PRIORITY 3: NORMAL CPU OPERATION
        else begin
            // Handshaking Logic
            if (~axi_awready && s_axi_awvalid && s_axi_wvalid) axi_awready <= 1;
            else axi_awready <= 0;

            if (~axi_wready && s_axi_wvalid && s_axi_awvalid) axi_wready <= 1;
            else axi_wready <= 0;

            if (axi_wready && s_axi_wvalid && axi_awready && s_axi_awvalid && ~axi_bvalid) axi_bvalid <= 1;
            else if (s_axi_bready && axi_bvalid) axi_bvalid <= 0;

            // Register Write Logic (Loading the Key)
            if (axi_wready && s_axi_wvalid && axi_awready && s_axi_awvalid) begin
                case (s_axi_awaddr[4:2])
                    3'h0: slv_reg0 <= s_axi_wdata; // Write Key 0
                    3'h1: slv_reg1 <= s_axi_wdata; // Write Key 1
                    3'h2: slv_reg2 <= s_axi_wdata; // Write Key 2
                    3'h3: slv_reg3 <= s_axi_wdata; // Write Key 3
                    3'h4: slv_reg4 <= s_axi_wdata; // Write Control (Enable)
                    default: ;
                endcase
            end
        end
    end

    // AXI READ LOGIC (Standard)
    always @(posedge clk) begin
        if (!reset_n) begin axi_arready <= 0; axi_rvalid <= 0; axi_rdata <= 0; end
        else begin
            if (~axi_arready && s_axi_arvalid) begin axi_arready <= 1; axi_rvalid <= 1; end
            else begin axi_arready <= 0; axi_rvalid <= 0; end
            
            if (~axi_arready && s_axi_arvalid) begin
                case (s_axi_araddr[4:2])
                    3'h0: axi_rdata <= slv_reg0;
                    3'h1: axi_rdata <= slv_reg1;
                    3'h2: axi_rdata <= slv_reg2;
                    3'h3: axi_rdata <= slv_reg3;
                    3'h4: axi_rdata <= slv_reg4;
                    default: axi_rdata <= 0;
                endcase
            end
        end
    end

    // =====================================================================
    // 2. THE IRON HEART (AES INSTANTIATION)
    // =====================================================================
    // We map the registers directly to the AES Core wires
    wire [127:0] dynamic_key = {slv_reg3, slv_reg2, slv_reg1, slv_reg0};
    wire engine_enable = slv_reg4[0];

    wire [127:0] aes_data_out;
    wire         aes_valid_out;

    // Connect the Modular AES Core
    aes_core iron_heart (
        .clk(clk),
        .reset_n(reset_n),
        .enable(s_axis_tvalid && m_axis_tready),
        .key(dynamic_key),
        .data_in(s_axis_tdata),
        .data_out(aes_data_out),
        .valid_out(aes_valid_out)
    );

    // =====================================================================
    // 3. OUTPUT PIPELINE & SECURITY GATE
    // =====================================================================
    always @(posedge clk) begin
        if (!reset_n) begin
            m_axis_tdata  <= 0;
            m_axis_tvalid <= 0;
            m_axis_tlast  <= 0;
            m_axis_tkeep  <= 0;
        end else begin
            // SECURITY GATE:
            // If Engine is ENABLED, output the AES Result.
            // If Engine is DISABLED (Lockdown), output ZEROES.
            
            if (aes_valid_out) begin
                if (engine_enable) begin
                    m_axis_tdata <= aes_data_out; // Encrypted Data
                end else begin
                    m_axis_tdata <= 128'h0;       // Lockdown (Zeroize)
                end
                
                m_axis_tvalid <= 1;
                m_axis_tlast  <= s_axis_tlast; 
                m_axis_tkeep  <= s_axis_tkeep;
            end else if (m_axis_tready) begin
                m_axis_tvalid <= 0;
            end
        end
    end

    // Backpressure
    assign s_axis_tready = m_axis_tready;

endmodule