# Meeting 2 — first experimental RTL milestone (NOT UCIe compliance)

## Historical repo audit (21 October 2026)
The baseline main-branch commit was `e679eb306d54664f195c227aec7e5862abb3f69f`. Existing RTL includes `elastic_buffer`, `credit_tx`, `crc16_ccitt`, `link_manager`, `stream_adapter`, and SystemVerilog tests. Those are **generic** blocks, not an established standards-accurate UCIe FDI/RDI/CRC/replay implementation.

## Connection to Dr. Larsen's feedback
- Begin with a small implementation, do meaningful work in synthesizable RTL.
- Use behavioral abstraction for physical propagation and reproducible faults.
- Check a single bit-flip in a fully observed system.
- Later explore replay storage vs. hardware resources; do not treat storage experiments as UCIe normative before checking the specific format/mode.
- Consider OpenROAD for physical cost estimates once implementation is stable.

## Implemented on feature branch
| File | Purpose |
|---|---|
| `rtl/experimental_stopwait_tx.sv` | Generic synthesizable one-outstanding-frame TX and retained data for retry |
| `rtl/experimental_stopwait_rx.sv` | Generic synthesizable RX CRC check, deduplication, output buffering |
| `tb/experimental_fault_link.sv` | Simulation-only single CRC-bit corruption |
| `tb/tb_experimental_stopwait.sv` | 24-payload independent end-to-end scoreboard, backpressure and single retransmission expectation |
| `scripts/run_experimental_stopwait.sh` | Fails closed if Icarus Verilog is unavailable |
| `.github/workflows/experimental-rtl.yml` | Remote RTL regression, subject to GitHub Actions availability |

The frame layout `{1-bit sequence, 32-bit data, CRC-16/CCITT-FALSE}`, retransmission policy, and acknowledgment protocol here are **not UCIe constructs**. They are a teaching demonstrator and cannot support any compliance claim.

## Acceptance conditions for generic experiment
- 24 accepted payloads must be delivered exactly once, in order.
- Repeated sink backpressure does not corrupt held payloads.
- The link corrupts exactly one accepted frame; RX reports exactly one CRC error.
- TX performs exactly one retransmission and no outstanding payload remains.
- An actual Icarus RTL simulation run must complete without a fatal error.

**Simulation execution:** Not confirmed by this document. Check GitHub Actions run and logs. The source-authoring container had no `iverilog`, `vvp`, `verilator`, `yosys`, or `openroad`.

## Critical specification gate
The official UCIe site provides the detailed 3.0 specification by request:
https://www.uciexpress.org/specifications

Before any UCIe-specific RTL:
1. Decide Standard 2D mode and protocol/flit format.
2. Extract exact FDI/RDI contracts from the authorized specification.
3. Validate CRC coverage, bit ordering, ACK/NACK rules, sequence fields and retry buffer ownership.
4. Map each behavior to specification revision/section and independent test.
5. Replace or segregate generic educational ARQ from normative adapter RTL.

## Replay-depth and physical-design work
No buffer-depth-versus-area/reliability results have been measured in this milestone. The one-outstanding-frame prototype is not a compliant UCIe replay engine, nor an independent multi-depth experiment.

Future study: validate mode-specific replay rules, write a depth-parameterized storage RTL with independent model, run deterministic and randomized tests, then synthesize mapped alternatives under the same libraries and constraints. Only then run an OpenROAD flow.

OpenROAD: https://openroad.org/

## Prioritized next task
Obtain full official spec, freeze FDI-focused interface contract, and validate the actual GitHub CI logs. Repair any failing RTL tests before adding additional features.
