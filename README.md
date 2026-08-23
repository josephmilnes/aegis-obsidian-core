# Project AEGIS: Obsidian Core

**Project AEGIS Obsidian Core: The foundational hardware and software repository for the Vault Network. An impenetrable, air-gapped mesh utilizing RISC-V, FPGAs, and seL4 to engineer a sovereign internet and the terrestrial primitives for future cosmic infrastructure.**

## The Vision: The Vault Network

The current internet architecture is fundamentally broken, relying on implicit trust and vulnerable endpoint execution. Project AEGIS abandons this paradigm. We are building the **Obsidian Web**—a decentralized network of physical, consumer-hosted data vaults.

By executing all legacy web traffic in a volatile, headless Render Plane and bridging it via a one-way physical data diode, we permanently eradicate 100% of stateful malware and centralized data harvesting. As the network reaches critical mass, nodes will utilize the **Meridian Protocol** to communicate directly, bypassing ISP surveillance through constant-bandwidth chaff injection and polymorphic routing.

## Current Hardware State: The Minimum Viable Vault (MVV)

This repository currently reflects the **Minimum Viable Vault (MVV)** phase of development. We are proving the core Zero-Trust primitives on silicon before scaling to the full macro-architecture.

### What is currently implemented (The MVV):

* **The Iron Heart:** A functional AES-256 hardware encryption core operating in real-time.
* **Tamper Mechanics:** Hardware-enforced kill-switch logic integrated directly into the AXI-Lite register bank. If the physical tamper mesh is breached, decryption keys are zeroized instantly.
* **Single-Drive Architecture:** The current PCIe/XDMA configuration is constrained to interface with a **single NVMe SSD** to prove the cryptographic pipeline and hardware bridging.
* **The Genesis ROM:** An immutable, hardware-synthesized record of the node's origin parameters burned directly into the gate logic.

### What is pending (The Proof of Concept):

* **10x NVMe RAID-Z Array:** The final hardware architecture requires a 10-drive array for cryptographic sharding and proof-of-storage redundancy. The XDMA and AXI interconnects will be scaled in a future release.
* **Bare-Metal Drivers:** Legacy hardware drivers bridging the FPGA logic to the RISC-V execution plane are currently being extracted from archived development environments. These will be committed iteratively as they are sanitized and ported to the seL4/Rust ecosystem.

## Repository Architecture

* `docs/`: Architectural whitepapers, manifestos, and API specifications
* `hardware/`: FPGA Silicon (Zone 3 Vault & Ingress)
* `hardware/constraints/`: Physical I/O pinouts and Tamper Mesh assignments
* `hardware/sim/`: Testbenches proving the Bio-Hash unlock and Tamper Kill Switch
* `hardware/scripts/`: Vivado Tcl scripts for automated block design generation
* `hardware/src/`: Raw gate-level Verilog logic (AES Core, Vault Controller, ROM)
* `software/`: Application layer and execution runtimes
* `software/firmware/scripts/`: XSCT automation scripts to compile the bare-metal application[cite: 11]
* `software/firmware/src/`: Keymaster application code (`main.c`, `sha_256.c`, `lscript.ld`)[cite: 14, 15]
* `CONTRIBUTING.md`: Contribution guidelines and PR requirements
* `HARDWARE-LICENSE.txt`: CERN-OHL-S License text
* `LICENSE`: GNU GPLv3 License text
* `README.md`: Main repository documentation

## Getting Started (Hardware Engineers)

To audit or compile the Obsidian Core silicon primitives, you do not need to download bloated `.xpr` files.

1. Clone this repository.
2. Open the Vivado 2025.2 Tcl Shell.
3. Navigate to the `hardware/scripts/` directory.
4. Execute the automated build script: `source aegis_mvv.tcl`[cite: 12]

This script will automatically pull the Verilog modules, apply the ZCU106 PCIe constraints, and reconstruct the block design and AXI interconnects. You can simulate the cryptographic handshake and tamper-kill switch via the provided `aegis_tb.v` testbench.

## Contributing to AEGIS

This architecture is designed to protect humanity from centralized authority; it cannot be built behind closed doors. We welcome contributions from cryptographers, FPGA engineers, and systems developers.

Please read the `CONTRIBUTING.md` file before submitting a Pull Request:

* All PRs must be submitted to the `dev-mvv` staging branch.
* Tag your PRs with `[HW]` for silicon/Vivado modifications or `[OS]` for software/seL4 modifications.
* **Zero-Trust Enforcement:** All commits must be signed with a verified GPG key. Unsigned commits will be automatically rejected by the CI/CD pipeline.

## Architect

**Joseph Daniel Milnes**

## Licensing

Project AEGIS utilizes a dual-license structure to ensure absolute sovereignty and transparency across both physical and digital domains.

* **Software & Documentation:** All software, microkernel modifications, routing logic, and documentation are licensed under the [GNU General Public License v3.0].
* **Hardware & Silicon:** All FPGA Verilog HDL, Vivado block designs, and physical board constraints located in the `/hardware` directory are strictly licensed under the [CERN Open Hardware Licence Version 2 - Strongly Reciprocal (CERN-OHL-S)].
