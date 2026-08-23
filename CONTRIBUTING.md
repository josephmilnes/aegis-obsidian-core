# Contributing to Project AEGIS

First, thank you for stepping up. Project AEGIS is not just a software repository; it is an architectural blueprint for a sovereign, decentralized, and mathematically secure digital future.

Because we are engineering a Zero-Trust ecosystem designed to resist state-level adversaries and centralized capture, our contribution guidelines are stricter than standard open-source projects. Security is not an afterthought; it is our physical baseline.

Please read this document carefully before submitting a Pull Request (PR).

## 1. The Zero-Trust Commit Policy (GPG Signing)

In a zero-trust architecture, identity must be mathematically verifiable. **We do not accept unsigned commits.**

* Every single commit submitted to this repository must be signed with a verified GPG key.
* If you submit a PR with unsigned commits, our CI/CD pipeline will automatically reject it.
* If you need help setting up GPG signing for your GitHub account, please refer to the [official GitHub documentation](https://docs.github.com/en/authentication/managing-commit-signature-verification/signing-commits).

## 2. Branching Strategy

We operate on a strict staging protocol to protect the integrity of the Obsidian Core hardware primitives and the seL4 microkernel.

* **`master`**: This branch is locked and reflects the current, stable baseline. It is currently locked to the **Minimum Viable Vault (MVV)** specification.
* **`dev-mvv`**: **All Pull Requests must target this branch.** This is our active staging ground for hardware scaling, Verilog refinement, and the incoming Rust/seL4 driver bridges.

## 3. Pull Request Tagging System

AEGIS bridges physical silicon, bare-metal firmware, capability-based operating systems, and network protocols. To ensure your PR is reviewed by the correct engineers, you must prefix your PR title with one of the following domain tags:

* **`[HW]` (Hardware):** Modifications to FPGA Verilog HDL, Vivado Tcl scripts, AXI interconnects, or physical constraints (e.g., `.xdc` files).
* **`[OS]` (Operating System):** Modifications to the seL4 microkernel, Rust runtimes, CSpace/VSpace capability routing, or hardware driver bridges.
* **`[NET]` (Network):** Logic relating to Polymorphic Routing, the Meridian Protocol, or delay-tolerant network concepts.
* **`[DOC]` (Documentation):** Updates to the whitepapers, API specifications, or READMEs.

*Example PR Title:* `[HW] Update AES core pipeline for 10x NVMe RAID-Z scaling`

## 4. Submission Checklist

Before you click "Create Pull Request", verify the following:

* [ ] My PR targets the `dev-mvv` branch.
* [ ] Every commit in this PR is GPG signed.
* [ ] I have prefixed my PR title with the correct domain tag (`[HW]`, `[OS]`, etc.).
* [ ] My code successfully compiles (Vivado synthesis for `[HW]`, or `make` for `[OS]`) without critical warnings.
* [ ] If I modified the Verilog, I have run the associated testbenches (e.g., `aegis_tb.v`) and they pass.
* [ ] I understand that my contributions will be dual-licensed under the **GPLv3** (for software) or **CERN-OHL-S** (for hardware).

## 5. The Review Process & The Conclave

Once submitted, your PR will enter the review pipeline.

1. **Automated Checks:** The CI/CD pipeline will verify GPG signatures and basic build integrity.
2. **Peer Audit:** Domain experts will audit the code for memory safety (Rust/seL4) or timing constraints (Verilog).
3. **Quorum Approval:** Major architectural changes will eventually require cryptographic multi-sig approval governed by the AEGIS Conclave protocol.

## 6. Code of Conduct

We are building the infrastructure for secure governance. Act with the professionalism, rigor, and respect that such an endeavor requires. Focus on the math, the logic, and the mission.
