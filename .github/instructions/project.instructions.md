---
description: Project context and Copilot guidelines for this VHDL/Verilog CPU design workspace
applyTo: "**/*.{v,vhd,do,mif,txt}" # Load for hardware sources, scripts, and docs
---

# Project context
- This workspace contains a simple CPU design implemented in VHDL/Verilog, with reference components under given_components/ and student/custom components under new_components/.
- Top-level integration appears in new_components/cpu.v with supporting control and datapath modules in new_components/.
- Memory initialization and test artifacts live at the repository root (e.g., *.mif, *.mpf) along with simulation scripts (wave.do).

# Coding guidelines
- Prefer minimal, targeted edits that preserve existing interfaces and signal names.
- Keep modules synthesizable unless the file is explicitly a testbench or simulation script.
- Do not change port ordering, widths, or active levels without user approval.
- Use consistent naming with existing RTL (snake_case for signals, module names already established).
- Avoid non-ASCII characters in RTL comments unless the file already uses them.
- When adding logic, include concise comments only for non-obvious behavior.

# Review and verification
- Call out behavioral risks, width mismatches, and clock/reset handling issues first.
- If changes affect control signals, confirm truth tables or state encodings.
- Suggest running simulation only if asked; otherwise provide what to verify.