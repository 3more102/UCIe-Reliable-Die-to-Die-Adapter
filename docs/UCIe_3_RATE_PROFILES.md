# UCIe 3.0 rate-profile capability and verification record

## Scope and standard basis

The UCIe Consortium's public [Specifications page](https://www.uciexpress.org/specifications) lists 48 GT/s and 64 GT/s for UCIe 3.0. That public overview establishes the target profile names and rates. It is not the complete normative specification. The full specification, PHY contract, lane configuration, clocking rules, and conformance requirements must be reviewed before making standards-conformance claims.

This repository currently contains a generic, single-clock ready/valid streaming demonstrator. `stream_adapter` now has the compile-time parameter `RATE_PROFILE_GT_S`, whose accepted values are 48 and 64. The `configured_rate_gt_s` output reports the selected supported value; unsupported values report zero and prevent datapath handshakes. The default value is 64. The parameter and fail-closed behavior are project-defined integration choices, not UCIe-defined encodings or behavior.

## Capability matrix

| Feature | Current evidence | Gap | Next action |
| --- | --- | --- | --- |
| 48 GT/s profile selection | `stream_adapter.RATE_PROFILE_GT_S=48`; directed test checks the reported value and runs data, stall, link-down, and credit-recovery cases | Digital parameter selection does not generate a 48 GT/s serial signal | Preserve this profile in the later PHY/clock model and verify against normative requirements |
| 64 GT/s target profile selection | `stream_adapter.RATE_PROFILE_GT_S=64` by default; directed test checks the reported value and runs the same datapath/reliability cases | No serializer, deserializer, lane PHY, or physical timing evidence | Add a PHY-facing model and timing evidence before claiming line-rate operation |
| Unsupported rate rejection | Directed 32 GT/s test expects a zero reported rate and disabled ingress/egress handshakes | Only values outside 48/64 are rejected; additional supported profiles require specification-backed changes | Expand the allowed set only when the architecture and selected UCIe revision justify it |
| Ready/valid buffering and link-down retention | Existing elastic buffer and stream regression; the integration now gates buffer consumption while the link/profile is inactive | No UCIe flit framing, link epoch, lane alignment, or protocol-aware recovery | Map these behaviors to the selected normative protocol and test reset/retrain interactions |
| Credit gating and recovery | Generic `credit_tx`; `tb_credit_tx_boundaries` covers saturation, full simultaneous send/return, depletion, refill, stall retention, and consumption; rate-profile test covers no-credit hold and return | Credit unit, initialization, return, saturation, and reset semantics are project-local | Replace or constrain the generic model from normative requirements and add boundary/error assertions |
| Prototype recovery state handling | `tb_link_manager` checks link-down during recovery and blocks recovery exit while `fault` remains asserted, even if `recovery_done` is high | `link_manager` state names and inputs are project-local and do not model normative UCIe initialization/recovery | Map initialization, recovery, and fault behavior to the selected normative UCIe revision |
| CRC and retry | Generic CCITT-16 calculator and independent mathematical checks exist on `main` | No UCIe-defined CRC coverage/field mapping or end-to-end replay/retry implementation | Derive CRC/retry behavior from the full specification; keep generic CRC tests labeled as infrastructure only |
| PHY and electrical link at 48/64 GT/s | No PHY RTL, electrical model, timing constraints, lab measurements, or interoperability report in this repository | No evidence for a physical lane rate or electrical performance | Add suitable PHY, timing, SI/PI, and hardware/interoperability evidence; otherwise report this as unverified |
| UCIe 3.0 conformance | No complete normative requirement mapping or conformance suite | The repository explicitly remains a generic prototype | Build a clause-to-RTL/test matrix from the complete specification and run the applicable conformance process |

## Clock and throughput interpretation

`clk` advances the functional ready/valid model. One rising edge represents a model step; it is not assigned a physical period and is not tied to GT/s. There is no per-lane transfer clock, serializer, deserializer, lane count, encoding model, clock-domain crossing, or PHY timing constraint. Consequently, this repository makes no throughput calculation from the selected profile. The value 48 or 64 is profile metadata and an enable/disable configuration check, not a measured or simulated transfer rate.

The RTL simulation can demonstrate profile selection and functional transaction/reliability behavior under both digital configurations. It cannot demonstrate that a PHY operates at 48 or 64 GT/s, that a UCIe link meets timing/electrical limits, or that two implementations interoperate.

## Reproduction commands

Run the two requested profiles and a negative configuration case with Icarus Verilog:

```sh
for profile in 48 64 32; do
  iverilog -g2012 -Ptb_stream_rate_profile.RATE_PROFILE_GT_S=${profile} -s tb_stream_rate_profile -o simv_rate_profile rtl/elastic_buffer.sv rtl/credit_tx.sv rtl/stream_adapter.sv tb/tb_stream_rate_profile.sv
  vvp simv_rate_profile
done

iverilog -g2012 -s tb_stream_link_hold -o simv_stream_hold rtl/elastic_buffer.sv rtl/credit_tx.sv rtl/stream_adapter.sv tb/tb_stream_link_hold.sv
vvp simv_stream_hold

iverilog -g2012 -s tb_link_manager -o simv_link rtl/link_manager.sv tb/tb_link_manager.sv
vvp simv_link

iverilog -g2012 -s tb_credit_tx_boundaries -o simv_credit_boundaries rtl/credit_tx.sv tb/tb_credit_tx_boundaries.sv
vvp simv_credit_boundaries
```

The GitHub Actions smoke workflow is configured to run these commands. The commands were also run locally with Icarus Verilog 12.0; local executable files were placed under `/tmp/ucie-rtl-tests` to keep the checkout clean. No GitHub Actions run was triggered for this local-only branch.

## Verification record

| Evidence type | Result |
| --- | --- |
| RTL source change | Added compile-time 48/64 profile selection, unsupported-rate gating, and link-down buffer retention |
| RTL simulation | PASS locally with Icarus Verilog 12.0 for both requested profiles, the unsupported-rate case, link-down retention, and the existing smoke/stress benches |
| Recovery/credit boundary regression | `tb_link_manager` recovery fault-priority case and `tb_credit_tx_boundaries` PASS locally with Icarus Verilog 12.0 |
| Synthesis / formal | Not run |
| Hardware measurement / interoperability | Not available |

## Progress log — 2026-10-14

1. Inspected `main` at `e679eb3`, its RTL, tests, and `rtl-smoke.yml`. The checkout was clean before work. GitHub showed four open draft PRs (#1–#4) and two additional elastic-buffer branches; they remain untouched.
2. Added the 48/64 compile-time selector, fail-closed handling for unsupported values, and buffer retention while the link/profile is inactive. Added directed profile tests for data transfer, output stalls, link-down recovery, credit starvation/return, and unsupported-profile rejection. Added the tests to the smoke workflow.
3. Installed Icarus Verilog 12.0 from the signed Ubuntu Noble archive after the configured snapshot mirror returned 502/503 errors. The profile tests initially passed; the pre-existing link-hold test exposed a sampling-time error in its own ready check, which was moved before the accepting edge without weakening the assertion.
4. RTL results: `tb_stream_rate_profile` at **48 GT/s PASS**, **64 GT/s PASS**, and unsupported **32 GT/s PASS (rejected)**; `tb_stream_link_hold` **PASS**; `tb_elastic_buffer` **PASS**; `tb_credit_tx` **PASS**; `tb_link_manager` **PASS**; `tb_elastic_buffer_random` **PASS (600 transactions)**; `tb_elastic_buffer_stress` **PASS (300 sent/received)**; integrated `stream_adapter` compile **PASS**.
5. Python/reference and static results: `python3 tb/tb_crc16_reference.py` **3 passed**; `git diff --check` **passed**. Synthesis, formal verification, hardware measurement, and interoperability remain unperformed.
6. Added a fault-priority condition to the project-local recovery FSM and extended its test to hold `fault` high through a completed-recovery indication. Added a directed generic credit boundary bench and CI step. The preconfigured package mirror returned HTTP 502; installed Icarus Verilog 12.0 from the signed Ubuntu Noble archive using a temporary package source. Both new benches PASS locally.

### Exact local commands for the profile and link-retention runs

```sh
iverilog -g2012 -Ptb_stream_rate_profile.RATE_PROFILE_GT_S=48 -s tb_stream_rate_profile -o /tmp/ucie-rtl-tests/rate48 rtl/elastic_buffer.sv rtl/credit_tx.sv rtl/stream_adapter.sv tb/tb_stream_rate_profile.sv
vvp /tmp/ucie-rtl-tests/rate48
iverilog -g2012 -Ptb_stream_rate_profile.RATE_PROFILE_GT_S=64 -s tb_stream_rate_profile -o /tmp/ucie-rtl-tests/rate64 rtl/elastic_buffer.sv rtl/credit_tx.sv rtl/stream_adapter.sv tb/tb_stream_rate_profile.sv
vvp /tmp/ucie-rtl-tests/rate64
iverilog -g2012 -Ptb_stream_rate_profile.RATE_PROFILE_GT_S=32 -s tb_stream_rate_profile -o /tmp/ucie-rtl-tests/rate32 rtl/elastic_buffer.sv rtl/credit_tx.sv rtl/stream_adapter.sv tb/tb_stream_rate_profile.sv
vvp /tmp/ucie-rtl-tests/rate32
iverilog -g2012 -s tb_stream_link_hold -o /tmp/ucie-rtl-tests/link_hold rtl/elastic_buffer.sv rtl/credit_tx.sv rtl/stream_adapter.sv tb/tb_stream_link_hold.sv
vvp /tmp/ucie-rtl-tests/link_hold
```
