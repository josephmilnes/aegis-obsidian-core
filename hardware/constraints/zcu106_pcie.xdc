# ------------------------------------------------------------------
# ZCU106 PCIe Constraints
# ------------------------------------------------------------------

# 1. PCIe Reference Clock (100 MHz from Motherboard)
# Location: MGTREFCLK0_224 (Pins AB8/AB7)
set_property PACKAGE_PIN AB8 [get_ports {pcie_ref_clk_clk_p[0]}]
set_property PACKAGE_PIN AB7 [get_ports {pcie_ref_clk_clk_n[0]}]
create_clock -period 10.000 -name pcie_ref_clk [get_ports {pcie_ref_clk_clk_p[0]}]

# 2. PCIe Reset (Active Low)
# Location: Bank 65 (Pin N11)
set_property PACKAGE_PIN N11 [get_ports pcie_perstn]
set_property IOSTANDARD LVCMOS18 [get_ports pcie_perstn]
set_property PULLUP true [get_ports pcie_perstn]

# 3. GT Location (The High Speed Transceivers)
# We lock the XDMA to the specific Quad 224 connected to the slot.
set_property LOC GTHE4_COMMON_X1Y6 [get_cells -hierarchical -filter {NAME =~ *pcie4_ip_i/inst/common_inst/gthe4_common_gen.GTHE4_COMMON_PRIM_INST}]

# TAMPER MESH SENSOR (Dummy Assignment for Bitstream Generation)
set_property PACKAGE_PIN AN14 [get_ports tamper_mesh_sense]
set_property IOSTANDARD LVCMOS18 [get_ports tamper_mesh_sense]
