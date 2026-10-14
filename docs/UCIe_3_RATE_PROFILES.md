# UCIe 3.0 rate-profile capability and verification record

## Scope and standard basis

The UCIe Consortium's public [Specifications page](https://www.uciexpress.org/specifications) lists 48 GT/s and 64 GT/s for UCIe 3.0. That public overview establishes the target profile names and rates. It is not the complete normative specification. The full specification, PHY contract, lane configuration, clocking rules, and conformance requirements must be reviewed before making standards-conformance claims.

This repository currently contains a generic, single-clock ready/valid streaming demonstrator. `stream_adapter` now has the compile-time parameter `RATE_PROFILE_GT_S`, whose accepted values are 48 and 64. The `configured_rate_gt_s` output reports the selected supported value; unsupported values report zero and prevent datapath handshakes. The default value is 64. The parameter and fail-closed behavior are project-defined integration choices, not UCIe-defined encodings or behavior.

## Public UCIe 3.0 feature mapping

The UCIe Consortium's public overview lists the following UCIe 3.0 features. This is a public-summary mapping, not a clause-by-clause conformance assessment; the page says the full specifications are available by request. No normative encoding, field width, timing, or behavior is inferred from this overview.

| Publicly listed UCIe 3.0 feature | Current repository evidence | Gap | Next action |
| --- | --- | --- | --- |
| 48 GT/s and 64 GT/s data rates | Compile-time digital profile selector, per-profile RTL simulation, and generic synthesis | The selector is metadata; there is no PHY, serializer, physical clock, or measured line rate | Obtain and implement the selected PHY contract; add rate-specific timing/physical evidence |
| Extended sideband channel reaching up to 100 mm | None; no sideband channel or package model | No sideband interface, channel, or reach model | Review normative sideband rules and package assumptions before adding a model |
| Continuous-transmission protocols through mappings in Raw Mode | None; the ready/valid stream is a project-local datapath | No UCIe protocol mapping, Raw Mode, or continuous-transmission behavior | Implement only from the full specification and selected protocol mapping |
| Early firmware download using Management Transport Protocol (MTP) | None; no management transport or firmware-download flow | No MTP messages, ordering, or initialization behavior | Review normative MTP and initialization requirements, then add directed tests |
| Priority sideband packets | None; no sideband scheduler or packet model | No priority encoding, arbitration, or latency behavior | Derive packet and scheduling behavior from the specification |
| Fast throttle and emergency-shutdown notifications | None; no system-level notification or power-control path | No notification path or receiver response | Define interface boundaries from the specification and test sequencing/fault cases |
| Open Drain Pins for bidirectional events | None; no pin-level or electrical I/O model | No pad behavior, pull-up, or electrical verification | Add only with PHY/pad requirements and suitable electrical evidence |
| Runtime recalibration and L2 optimization | None; no PHY calibration or power-management state machine | No calibration, L2, or PHY state behavior | Map normative state transitions and PHY control interfaces before implementation |
| Backward compatibility with previous UCIe specifications | None; no normative revision mapping or interoperability suite | Compatibility has not been implemented or tested | Select prior revisions and run the applicable conformance/interoperability tests |

## Capability matrix

| Feature | Current evidence | Gap | Next action |
| --- | --- | --- | --- |
| 48 GT/s profile selection | `stream_adapter.RATE_PROFILE_GT_S=48`; directed and randomized tests check the profile and run stream, backpressure, link-down, reset, and credit-accounting cases | Digital parameter selection does not generate a 48 GT/s serial signal | Preserve this profile in the later PHY/clock model and verify against normative requirements |
| 64 GT/s target profile selection | `stream_adapter.RATE_PROFILE_GT_S=64` by default; directed and randomized tests check the profile and run the same datapath/reliability cases | No serializer, deserializer, lane PHY, or physical timing evidence | Add a PHY-facing model and timing evidence before claiming line-rate operation |
| Unsupported rate rejection | Directed 32 GT/s test expects a zero reported rate and disabled ingress/egress handshakes | Only values outside 48/64 are rejected; additional supported profiles require specification-backed changes | Expand the allowed set only when the architecture and selected UCIe revision justify it |
| Ready/valid buffering and link-down retention | Existing elastic buffer and stream regression; the integration now gates buffer consumption while the link/profile is inactive | No UCIe flit framing, link epoch, lane alignment, or protocol-aware recovery | Map these behaviors to the selected normative protocol and test reset/retrain interactions |
| Digital reset isolation and recovery | `tb_stream_reset` at 48 and 64 profiles checks no handshakes during reset, clears pending data and credits, rejects reset-period traffic, and delivers a fresh post-reset word once | Reset behavior is a project-defined single-clock model choice; PHY and protocol-layer reset sequencing are absent | Define reset sequencing from the selected UCIe revision and integrate it across adapter/PHY boundaries |
| Integrated digital datapath ordering | `tb_stream_random` sends/receives 228 checked transactions under randomized link state, backpressure, and credit return for each profile | Single-clock model has no PHY clock, flit/lane alignment, or UCIe throughput representation | Retain as infrastructure coverage and extend with normative adapter framing when the full spec is available |
| Generic RTL synthesis at both profiles | Yosys 0.33 `hierarchy -check`, `check`, and `synth` pass for the integrated adapter at 48 and 64 | Generic synthesis has no target cell library, timing constraints, physical design, or PHY model | Add target-specific constraints and implementation evidence only after a PHY and target technology are selected |
| Credit gating and recovery | Generic `credit_tx`; boundary bench covers saturation, simultaneous send/return, depletion, refill, stall retention, and consumption; randomized adapter bench checks credit accounting; directed profile test covers no-credit hold and return | Credit unit, initialization, return, saturation, and reset semantics are project-local | Replace or constrain the generic model from normative requirements and add boundary/error assertions |
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

for profile in 48 64; do
  iverilog -g2012 -Ptb_stream_reset.RATE_PROFILE_GT_S=${profile} -s tb_stream_reset -o simv_stream_reset rtl/elastic_buffer.sv rtl/credit_tx.sv rtl/stream_adapter.sv tb/tb_stream_reset.sv
  vvp simv_stream_reset
done

for profile in 48 64; do
  iverilog -g2012 -Ptb_stream_random.RATE_PROFILE_GT_S=${profile} -s tb_stream_random -o simv_stream_random rtl/elastic_buffer.sv rtl/credit_tx.sv rtl/stream_adapter.sv tb/tb_stream_random.sv
  vvp simv_stream_random
done
```

The GitHub Actions smoke workflow is configured to run these tests and generic synthesis at both supported profiles. The simulation commands were run locally with Icarus Verilog 12.0; local executable files were placed under `/tmp/ucie-rtl-tests` to keep the checkout clean. The synthesis commands were run locally with Yosys 0.33. The feature branch has been uploaded. The GitHub combined-status lookup returned no checks for its final commit at the time of this record, so hosted CI remains unconfirmed.

Run generic Yosys elaboration, structural checks, and synthesis for the 48 and 64 GT/s digital profile configurations:

```sh
for profile in 48 64; do
  yosys -Q -p "read_verilog -sv rtl/elastic_buffer.sv rtl/credit_tx.sv rtl/stream_adapter.sv; chparam -set RATE_PROFILE_GT_S ${profile} stream_adapter; hierarchy -check -top stream_adapter; proc; opt; check; synth -top stream_adapter; check; stat"
done
```

## Verification record

| Evidence type | Result |
| --- | --- |
| RTL source change | Added compile-time 48/64 profile selection, unsupported-rate gating, and link-down buffer retention |
| RTL simulation | PASS locally with Icarus Verilog 12.0 for both requested profiles, the unsupported-rate case, link-down retention, and the existing smoke/stress benches |
| Recovery/credit boundary regression | `tb_link_manager` recovery fault-priority case and `tb_credit_tx_boundaries` PASS locally with Icarus Verilog 12.0 |
| Reset isolation regression | `tb_stream_reset` PASS locally for both 48 and 64 digital profiles; no handshakes during reset, pending-state flush, and fresh post-reset transfer verified |
| Randomized integrated datapath | `tb_stream_random` PASS at both profiles: 228 correctly ordered transactions each, with exact 2-bit credit-model accounting |
| Generic synthesis | PASS locally with Yosys 0.33 at 48 and 64 profiles; `hierarchy -check`, pre/post-synthesis `check`, and generic `synth` completed without errors. No target library or timing constraints were used. |
| Formal verification | Not run |
| Hardware measurement / interoperability | Not available |

## Progress log — 2026-10-14

1. Inspected `main` at `e679eb3`, its RTL, tests, and `rtl-smoke.yml`. The checkout was clean before work. GitHub showed four open draft PRs (#1–#4) and two additional elastic-buffer branches; they remain untouched.
2. Added the 48/64 compile-time selector, fail-closed handling for unsupported values, and buffer retention while the link/profile is inactive. Added directed profile tests for data transfer, output stalls, link-down recovery, credit starvation/return, and unsupported-profile rejection. Added the tests to the smoke workflow.
3. Installed Icarus Verilog 12.0 from the signed Ubuntu Noble archive after the configured snapshot mirror returned 502/503 errors. The profile tests initially passed; the pre-existing link-hold test exposed a sampling-time error in its own ready check, which was moved before the accepting edge without weakening the assertion.
4. RTL results: `tb_stream_rate_profile` at **48 GT/s PASS**, **64 GT/s PASS**, and unsupported **32 GT/s PASS (rejected)**; `tb_stream_link_hold` **PASS**; `tb_elastic_buffer` **PASS**; `tb_credit_tx` **PASS**; `tb_link_manager` **PASS**; `tb_elastic_buffer_random` **PASS (600 transactions)**; `tb_elastic_buffer_stress` **PASS (300 sent/received)**; integrated `stream_adapter` compile **PASS**.
5. Python/reference and static results: `python3 tb/tb_crc16_reference.py` **3 passed**; `git diff --check` **passed**. Synthesis, formal verification, hardware measurement, and interoperability remain unperformed.
6. Added a fault-priority condition to the project-local recovery FSM and extended its test to hold `fault` high through a completed-recovery indication. Added a directed generic credit boundary bench and CI step. The preconfigured package mirror returned HTTP 502; installed Icarus Verilog 12.0 from the signed Ubuntu Noble archive using a temporary package source. Both new benches PASS locally.
7. Uploaded the two change sets to `feat/ucie-3-rate-profiles-20261014` using the GitHub integration after shell `git push` could not authenticate. The uploaded branch tree matches the locally tested tree. The combined-status lookup returned no checks; no PR was created.
8. Gated the stream adapter's active path during reset and added reset isolation/flush/recovery tests. `tb_stream_reset` passes at 48 and 64 GT/s digital profiles with Icarus Verilog 12.0. This reset contract is project-defined and is not a UCIe normative reset sequence.
9. Added a deterministic randomized stream-adapter scoreboard, output-stall check, link-down check, and independent bounded-credit model. Both profile runs PASS with 228 transactions delivered; this verifies the generic digital datapath only.
10. Installed Yosys 0.33 from the signed Ubuntu Noble archive and synthesized `stream_adapter` at 48 and 64 profile parameter values. Both runs pass hierarchy and structural checks and complete generic synthesis. Added the same checks to GitHub Actions and brought the existing randomized/stress elastic-buffer and CRC reference tests into that workflow; no hosted result is yet confirmed.
11. Expanded the public-feature mapping against the UCIe Consortium's current UCIe 3.0 overview, labeling unimplemented features and normative details that remain unresolved.

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
