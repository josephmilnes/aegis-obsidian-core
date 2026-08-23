`timescale 1ns / 1ps

module aegis_tb;

    // --------------------------------------------------------
    // 1. SIGNALS
    // --------------------------------------------------------
    reg clk;
    reg reset_n;
    reg tamper_mesh_sense; // 1=Safe, 0=Cut
    
    // Stream Interface
    reg  [127:0] s_axis_tdata;
    reg          s_axis_tvalid;
    reg          s_axis_tlast;
    reg  [15:0]  s_axis_tkeep;
    wire         s_axis_tready;
    
    wire [127:0] m_axis_tdata;
    wire         m_axis_tvalid;
    wire         m_axis_tlast;
    wire [15:0]  m_axis_tkeep;
    wire         m_axis_tready; 

    // Control Interface (AXI Lite)
    reg  [4:0]   s_axi_awaddr;
    reg          s_axi_awvalid;
    wire         s_axi_awready;
    reg  [31:0]  s_axi_wdata;
    reg  [3:0]   s_axi_wstrb;
    reg          s_axi_wvalid;
    wire         s_axi_wready;
    wire [1:0]   s_axi_bresp;
    wire         s_axi_bvalid;
    reg          s_axi_bready;

    // Unused Read Channels
    wire [31:0]  s_axi_rdata;
    wire [1:0]   s_axi_rresp;
    wire         s_axi_rvalid;
    reg          s_axi_rready; 

    // --------------------------------------------------------
    // 2. INSTANTIATE THE DUT (Your Updated Controller)
    // --------------------------------------------------------
    aegis_vault_controller #(
        .C_DATA_WIDTH(128),
        .C_S_AXI_DATA_WIDTH(32),
        .C_S_AXI_ADDR_WIDTH(5)
    ) dut (
        .clk(clk),
        .reset_n(reset_n),
        .tamper_mesh_sense(tamper_mesh_sense), // CONNECTED HERE
        
        .s_axis_tdata(s_axis_tdata),
        .s_axis_tvalid(s_axis_tvalid),
        .s_axis_tready(s_axis_tready),
        .s_axis_tlast(s_axis_tlast),
        .s_axis_tkeep(s_axis_tkeep),
        
        .m_axis_tdata(m_axis_tdata),
        .m_axis_tvalid(m_axis_tvalid),
        .m_axis_tready(m_axis_tready), 
        .m_axis_tlast(m_axis_tlast),
        .m_axis_tkeep(m_axis_tkeep),
        
        .s_axi_awaddr(s_axi_awaddr),
        .s_axi_awvalid(s_axi_awvalid),
        .s_axi_awready(s_axi_awready),
        .s_axi_wdata(s_axi_wdata),
        .s_axi_wstrb(s_axi_wstrb),
        .s_axi_wvalid(s_axi_wvalid),
        .s_axi_wready(s_axi_wready),
        .s_axi_bresp(s_axi_bresp),
        .s_axi_bvalid(s_axi_bvalid),
        .s_axi_bready(s_axi_bready),
        
        .s_axi_araddr(0), .s_axi_arvalid(0), .s_axi_arready(),
        .s_axi_rdata(s_axi_rdata), .s_axi_rresp(s_axi_rresp), 
        .s_axi_rvalid(s_axi_rvalid), .s_axi_rready(s_axi_rready)
    );

    // --------------------------------------------------------
    // 3. CLOCK & DEFAULTS
    // --------------------------------------------------------
    assign m_axis_tready = 1'b1; 

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // --------------------------------------------------------
    // 4. THE LIVE BIO-HASH LISTENER
    // --------------------------------------------------------
    integer file_handle;
    integer scan_result;
    reg [31:0] received_hash;
    reg        hash_detected;

    initial begin
        // A. INITIALIZATION
        $display("--- AEGIS SILICON SIMULATION START ---");
        reset_n = 0;
        
        // *** DYNAMIC SECURITY CHECK ***
        // We start with the mesh INTACT (1).
        tamper_mesh_sense = 1; 
        
        s_axis_tvalid = 0;
        s_axis_tdata = 0;
        s_axi_awvalid = 0;
        s_axi_wvalid = 0;
        s_axi_bready = 1;
        s_axi_rready = 1;
        
        hash_detected = 0;
        received_hash = 32'h0;

        #100;
        reset_n = 1;
        $display("[STATUS] OBSIDIAN CORE: LISTENING FOR BIO-HASH...");

        // B. LISTEN LOOP
        while (hash_detected == 0) begin
            #100; 
            // Read "vault_trigger.dat" expecting a HEX string
            file_handle = $fopen("C:\\aegis_exchange\\vault_trigger.dat", "r");
            
            if (file_handle != 0) begin
                // %h reads hexadecimal
                scan_result = $fscanf(file_handle, "%h", received_hash);
                $fclose(file_handle);
                
                if (received_hash != 0) begin
                    $display("[NETWORK] SIGNAL DETECTED. PAYLOAD: %h", received_hash);
                    hash_detected = 1;
                end
            end
        end

        // C. AUTHENTICATION LOGIC
        #100;
        
        if (received_hash == 32'hDEADBEEF) begin
            $display("[AUTH] BIO-HASH VERIFIED. UNLOCKING CORE.");
            
            // 1. Write Hash to Registers
            write_register(5'h00, received_hash); 
            write_register(5'h04, 32'hCAFEBABE);  
            write_register(5'h08, 32'h00000000);
            write_register(5'h0C, 32'hFFFFFFFF);
            
            // 2. Enable Engine
            write_register(5'h10, 32'h00000001); 
            
            // 3. Test Data Flow
            #50;
            $display("--- SESSION ACTIVE: STREAMING DATA ---");
            s_axis_tdata = 128'hAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA; 
            s_axis_tvalid = 1;
            #10;
            s_axis_tdata = 128'hBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB;
            #10;
            s_axis_tvalid = 0;
            
        end else begin
            $display("[AUTH] ACCESS DENIED. INVALID HASH: %h", received_hash);
            $finish; 
        end

        // D. TAMPER TEST (The Kill Switch)
        // This runs AFTER the successful session to prove it can kill a live key.
        #200;
        $display("--- SECURITY EVENT: WIRE MESH CUT ---");
        
        // *** HERE IS THE DYNAMIC CHANGE ***
        tamper_mesh_sense = 0; 
        
        #20;
        // Verify Destruction
        if (dut.slv_reg0 == 0) 
            $display("[SUCCESS] KEYS VAPORIZED. SYSTEM SECURE.");
        else 
            $display("[FAILURE] CRITICAL: KEYS REMAIN.");

        $finish;
    end

    // AXI WRITE TASK
    task write_register(input [4:0] addr, input [31:0] val);
        begin
            @(posedge clk);
            s_axi_awaddr = addr;
            s_axi_awvalid = 1;
            s_axi_wdata = val;
            s_axi_wvalid = 1;
            s_axi_wstrb = 4'hF;
            wait(s_axi_awready && s_axi_wready);
            @(posedge clk);
            s_axi_awvalid = 0;
            s_axi_wvalid = 0;
            @(posedge clk);
        end
    endtask

endmodule
