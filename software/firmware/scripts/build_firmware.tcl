# AEGIS FIRMWARE BUILDER (XSCT Script)
# Usage: Open Vitis Terminal -> Run: xsct build_firmware.tcl

# ----------------------------------------------------------------------
# 1. SET RELATIVE PATHS
# ----------------------------------------------------------------------
# The script is in: aegis-core/software/firmware/scripts/

# 'fw_dir' = aegis-core/software/firmware
set fw_dir [file normalize ".."]

# 'repo_root' = aegis-core/ (Up 3 levels: scripts -> firmware -> software -> root)
set repo_root [file normalize "$fw_dir/../../"]

# 'ws_dir' = aegis-core/software/firmware/workspace (The junk folder)
set ws_dir [file normalize "$fw_dir/workspace"]

# 'src_dir' = aegis-core/software/firmware/src (Where your main.c lives)
set src_dir [file normalize "$fw_dir/src"]

# ----------------------------------------------------------------------
# 2. FIND THE HARDWARE (.xsa)
# ----------------------------------------------------------------------
# It looks in: aegis-core/hardware/fpga/build/
set hw_build_dir [file normalize "$repo_root/hardware/fpga/build"]
set xsa_file [glob -nocomplain "$hw_build_dir/*.xsa"]

if {$xsa_file eq ""} {
    puts "----------------------------------------------------------------"
    puts "CRITICAL ERROR: No .xsa hardware file found!"
    puts "Checked location: $hw_build_dir"
    puts "Please run the Vivado build first to generate the hardware."
    puts "----------------------------------------------------------------"
    exit 1
} else {
    puts "Found Hardware Definition: $xsa_file"
}

# ----------------------------------------------------------------------
# 3. CREATE FRESH WORKSPACE & PLATFORM
# ----------------------------------------------------------------------
puts "Creating Vitis Workspace at: $ws_dir"
setws $ws_dir

# Create the Board Support Package (BSP) drivers based on the XSA
platform create -name "obsidian_platform" -hw $xsa_file
domain create -name "standalone_domain" -os standalone -proc psu_cortexa53_0
platform generate

# ----------------------------------------------------------------------
# 4. CREATE APPLICATION & IMPORT SOURCE
# ----------------------------------------------------------------------
app create -name "obsidian_firmware" -platform "obsidian_platform" -domain "standalone_domain" -template "Empty Application"

# Link your clean 'src' folder into the project
importsources -name "obsidian_firmware" -path $src_dir -soft-link

# ----------------------------------------------------------------------
# 5. COMPILE
# ----------------------------------------------------------------------
puts "Compiling Aegis Firmware..."
app build -name "obsidian_firmware"

puts "----------------------------------------------------------------"
puts "  SUCCESS: Firmware Built."
puts "  Binary: $ws_dir/obsidian_firmware/Debug/obsidian_firmware.elf"
puts "----------------------------------------------------------------"
