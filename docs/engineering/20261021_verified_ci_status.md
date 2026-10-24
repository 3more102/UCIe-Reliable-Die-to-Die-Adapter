# Executed verification evidence — 2026-10-21

## Provenance
- Repository: `3more102/UCIe-Reliable-Die-to-Die-Adapter`
- Branch: `feat/meeting2-generic-link-20261021`
- Tested commit: `50e153641e94b7bd02a1ab123ce8e967c856b506`
- Workflow: **Experimental generic RTL regression (NOT UCIe compliance)**
- Successful run: https://github.com/3more102/UCIe-Reliable-Die-to-Die-Adapter/actions/runs/39605866474
- Existing smoke workflow: https://github.com/3more102/UCIe-Reliable-Die-to-Die-Adapter/actions/runs/39605866494 (success)
- Runner: GitHub-hosted Ubuntu, Icarus Verilog and Yosys installed in CI

## Recorded successful tests
1. Elastic buffer directed: PASS.
2. Generic credit transmitter: PASS.
3. Generic link manager: PASS.
4. Stream link-hold and recovery: PASS.
5. Random elastic buffer: PASS, 600 transactions.
6. Elastic buffer stress: PASS, 300 sent / 300 received.
7. Generic replay store: PASS, depth=4, wraparound, backpressure, no implicit retire.
8. Non-UCIe stop-and-wait link: PASS, 24 accepted, 24 delivered, 1 fault, 1 detected CRC error, 1 retry, 91 simulated cycles.

All tests above are **generic infrastructure tests**. No normative UCIe 3.0 compliance/FDI/retry assertions have been executed.

## Reproducible Yosys study
Workflow `bash scripts/run_generic_storage_sweep.sh` ran generic non-technology-mapped synthesis for DATA_WIDTH=32 and depths 4,8,16,32,64.

| Depth (words) | Payload capacity (bytes) | Generic Yosys cell count | Wire bits | Memory bits after memory pass |
|---:|---:|---:|---:|---:|
| 4 | 16 | 76 | 347 | 0 |
| 8 | 32 | 92 | 516 | 0 |
| 16 | 64 | 124 | 825 | 0 |
| 32 | 128 | 188 | 1414 | 0 |
| 64 | 256 | 316 | 2563 | 0 |

These internal generic counts are NOT technology-mapped area, standard-cell area, delay, power, or valid UCIe-replay performance. `memory; opt; stat` mapped memories into logic and registers for this analysis.

GitHub Actions uploaded full per-depth Yosys logs as artifact `generic-replay-storage-yosys-logs`.

## Bugs resolved
- Pre-existing `tb_stream_link_hold` sampled input-ready after the acceptance edge. The test was revised to check readiness before the handshake.
- The test then exposed an RTL issue: `stream_adapter` could drain its pending buffer during link-down. Fixed by gating ingress read readiness with `link_up`.
- Regression rerun passed.

## Remaining blocked work
- Full UCIe 3.0 specification access and format/profile freeze.
- Normative FDI/RDI ports, CRC and retry mapping.
- UVM verification with a compatible simulator.
- Technology-mapped synthesis area and STA.
- OpenROAD implementation and layout metrics.
- Statistical reliability study using standards-consistent replay semantics.
- Novelty assessment against verified literature.

**Conclusion:** This commit provides an independently checked *experimental generic reliability demonstrator* and initial storage-complexity trend, not a UCIe-compliant adapter.
