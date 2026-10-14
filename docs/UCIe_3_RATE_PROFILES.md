# UCIe 3.0 rate-profile capability and verification record

## Scope and standard basis

The UCIe Consortium's public [Specifications page](https://www.uciexpress.org/specifications) lists 48 GT/s and 64 GT/s for UCIe 3.0. That public overview establishes the target profile names and rates. It is not the complete normative specification. The full specification, PHY contract, lane configuration, clocking rules, and conformance requirements must be reviewed before making standards-conformance claims.

This repository currently contains a generic, single-clock ready/valid streaming demonstrator. `stream_adapter` now has the compile-time parameter `RATE_PROFILE_GT_S`, whose accepted values are 48 and 64. The `configured_rate_gt_s` output reports the selected supported value; unsupported values report zero and prevent datapath handshakes. The default value is 64. The parameter and fail-closed behavior are project-defined integration choices, not UCIe-defined encodings or behavior.

The reliability model uses the same parameter and reports the effective profile as 48 or 64, or zero when unsupported. `tb_profile_consistency` instantiates both digital layers with one shared parameter, compares the supported/effective profile indication, and transfers the same payload through both at 48 and 64. Its 32 case checks consistent fail-closed behavior.

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
| 48 GT/s profile selection | `stream_adapter.RATE_PROFILE_GT_S=48` and `reliable_stream_model.RATE_PROFILE_GT_S=48`; directed, randomized and reliability tests exercise profile configuration, data transfer, CRC rejection/retry, credit stalls, backpressure, and link recovery | Digital parameter selection does not generate a 48 GT/s serial signal | Preserve this profile in a later PHY/clock model and verify against normative requirements |
| 64 GT/s target profile selection | `stream_adapter.RATE_PROFILE_GT_S=64` and `reliable_stream_model.RATE_PROFILE_GT_S=64` by default; directed, randomized and reliability tests exercise the same digital behaviors | No serializer, deserializer, lane PHY, or physical timing evidence | Add a PHY-facing model and timing evidence before claiming line-rate operation |
| Shared profile consistency | `tb_profile_consistency` uses one compile-time setting for both layers; support/effective-rate outputs agree, and the same payload passes both datapaths for 48/64 | Digital profile agreement does not provide PHY clocks or rates | Retain the shared-parameter regression and add PHY-specific checks only with a defined PHY contract |
| Unsupported rate rejection | Directed 32 GT/s test expects a zero reported rate and disabled ingress/egress handshakes | Only values outside 48/64 are rejected; additional supported profiles require specification-backed changes | Expand the allowed set only when the architecture and selected UCIe revision justify it |
| Ready/valid buffering and link-down retention | Existing elastic buffer and stream regressions; stream wrapper ignores credit returns while inactive; generic replay state also holds through the project-local fault/recovery sequence | No UCIe flit framing, link epoch, lane alignment, or protocol-aware recovery; inactive-credit handling is a local policy | Map these behaviors to the selected normative protocol and test reset/retrain interactions |
| Digital reset isolation and recovery | `tb_stream_reset` at 48 and 64 profiles checks no handshakes during reset, clears pending data and credits, rejects reset-period traffic, and delivers a fresh post-reset word once | Reset behavior is a project-defined single-clock model choice; PHY and protocol-layer reset sequencing are absent | Define reset sequencing from the selected UCIe revision and integrate it across adapter/PHY boundaries |
| Integrated digital datapath ordering | `tb_stream_random` sends/receives 209 checked transactions under randomized link state, backpressure, and credit return for each profile after inactive-link credit gating | Single-clock model has no PHY clock, flit/lane alignment, or UCIe throughput representation | Retain as infrastructure coverage and extend with normative adapter framing when the full spec is available |
| Generic RTL synthesis at both profiles | Yosys 0.33 `hierarchy -check`, `check`, and `synth` pass for the integrated adapter at 48 and 64 | Generic synthesis has no target cell library, timing constraints, physical design, or PHY model | Add target-specific constraints and implementation evidence only after a PHY and target technology are selected |
| Credit gating and recovery | Generic `credit_tx`; boundary bench covers saturation, simultaneous send/return, depletion, refill, stall retention, and consumption; adapter wrapper ignores returns while inactive; randomized and directed profile benches check accounting | Credit unit, initialization, return, saturation, reset semantics, and inactive-link policy are project-local | Replace or constrain the generic model from normative requirements and add boundary/error assertions |
| Prototype recovery state handling | `tb_link_manager` checks link-down during recovery and blocks recovery exit while `fault` remains asserted, even if `recovery_done` is high | `link_manager` state names and inputs are project-local and do not model normative UCIe initialization/recovery | Map initialization, recovery, and fault behavior to the selected normative UCIe revision |
| CRC and retry | Generic CCITT-16 calculator, RTL check-value test, one-entry RX CRC checker, duplicate suppression, and stop-and-wait replay sender; directed and deterministic randomized corruption/NACK/retry-limit scenarios run at both profile labels; unit test rejects wrong-sequence ACKs | The project's CRC coverage, sequence, response, credit and retry rules are not UCIe-defined; no normative field mapping exists | Derive CRC/retry behavior from the full specification; keep generic CRC tests labeled as infrastructure only |
| Lost-frame and lost-response recovery | `tb_generic_replay_tx` proves exact timeout boundary, link-down pause, zero-disable behavior, and failure at the retry limit; integrated 48/64 tests separately drop an accepted abstract frame before RX and drop an ACK, then check credit-gated retry and no duplicate delivery | Timeout is a project-defined active-link model-cycle count (default 16; directed test uses 4), not a UCIe timing value; the hooks do not model physical or sideband errors | Replace the generic mechanism only after mapping normative retry/timeout behavior from the full specification |
| Reliability diagnostics | Integrated tests check saturating CRC-error, response-timeout, and link-recovery counters; randomized runs compare the status outputs with independent scoreboard counts | Counters and their 16-bit default width are project-defined diagnostics, not UCIe status encodings | Map standard error/status reporting only from normative requirements; retain internal counters as research telemetry |
| Integrated formal safety | Yosys SAT checks accepted-to-delivered ordering and payload integrity through 16 cycles with arbitrary sampled backpressure, credits, CRC faults, frame loss, response loss, link faults, and reset | Bounded safety only; no liveness, full-state proof, or normative UCIe behavior | Extend proof depth or add induction only after the protocol boundary is frozen |
| Stream wrapper formal reference | `formal_stream_adapter` checks exact one-entry buffer/credit behavior, shared 48/64 outputs, unsupported 32 rejection, and inactive-link credit gating against an independent model | Project-local policy and model widths only; no UCIe credit semantics | Keep this proof aligned with wrapper changes; replace local assumptions only from normative requirements |
| PHY and electrical link at 48/64 GT/s | No PHY RTL, electrical model, timing constraints, lab measurements, or interoperability report in this repository | No evidence for a physical lane rate or electrical performance | Add suitable PHY, timing, SI/PI, and hardware/interoperability evidence; otherwise report this as unverified |
| UCIe 3.0 conformance | No complete normative requirement mapping or conformance suite | The repository explicitly remains a generic prototype | Build a clause-to-RTL/test matrix from the complete specification and run the applicable conformance process |

## Clock and throughput interpretation

`clk` advances the functional ready/valid model. One rising edge represents a model step; it is not assigned a physical period and is not tied to GT/s. There is no per-lane transfer clock, serializer, deserializer, lane count, encoding model, clock-domain crossing, or PHY timing constraint. Consequently, this repository makes no throughput calculation from the selected profile. The value 48 or 64 is profile metadata and an enable/disable configuration check, not a measured or simulated transfer rate.

The RTL simulation can demonstrate profile selection and functional transaction/reliability behavior under both digital configurations. It cannot demonstrate that a PHY operates at 48 or 64 GT/s, that a UCIe link meets timing/electrical limits, or that two implementations interoperate.

## Project-defined digital reliability model

The `reliable_stream_model` loopback composes the project-local link manager, a one-word ingress elastic buffer, a one-entry stop-and-wait TX replay block, generic credit gating, and a one-entry RX CRC checker. The ingress queue can hold the next payload while replay waits for a response; the regression checks ordered delivery of two queued payloads after reset. Its internal test frame is `{one-bit sequence, 16-bit CRC, payload}`. CRC-16/CCITT-FALSE is calculated over `{sequence, payload}`. A new frame with the expected sequence is delivered once; a valid repeated sequence is ACKed and suppressed; a CRC mismatch is NACKed and raises a one-cycle error indication. Every accepted abstract channel attempt consumes one generic credit. The `drop_frame_i` test hook consumes that credit but removes the attempt before RX; `drop_response_i` removes an RX response before TX. Both hooks exercise timeout/replay logic and are not physical fault models. The default `MAX_RETRIES=2` permits two retransmissions following the first attempt. Exhaustion is sticky until reset. `RESPONSE_TIMEOUT_CYCLES=16` is a project-defined active-link model-clock count that pauses while link-down; zero disables it. It has no conversion to GT/s or UCIe timing. After timeout, a replay still waits for a fresh generic credit. Saturating, configurable-width outputs count CRC error pulses, response-timeout events, and recovery entries; they reset with the model and are project diagnostics, not UCIe status fields. The test-only `corrupt_crc_i` input injects CRC corruption at the abstract digital boundary.

Those framing, sequence, CRC coverage, ACK/NACK, credit, timeout and retry rules are local prototype decisions. The model's `phy_ready_i` is a single-clock digital backpressure signal; none of `phy_ready_i`, `corrupt_crc_i`, `drop_frame_i` or `drop_response_i` models electrical PHY behavior. Profile values 48 and 64 leave the digital clock relationship unchanged.

## Reproduction commands

Run the two requested profiles and a negative configuration case with Icarus Verilog:

```sh
mkdir -p /tmp/ucie-rtl-tests
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

The GitHub Actions smoke workflow runs these tests and generic synthesis at both supported profiles. The simulation commands were run locally with Icarus Verilog 12.0; local executable files were placed under `/tmp/ucie-rtl-tests` to keep the checkout clean. The synthesis commands were run locally with Yosys 0.33. GitHub Actions run #112 for commit `124005a` and run #116 for commit `3666557` completed successfully on the feature branch. No pull request was created.

Run the additional generic reliability-model regressions:

```sh
mkdir -p /tmp/ucie-rtl-tests
iverilog -g2012 -s tb_crc16_ccitt -o /tmp/ucie-rtl-tests/crc_rtl rtl/crc16_ccitt.sv tb/tb_crc16_ccitt.sv
vvp /tmp/ucie-rtl-tests/crc_rtl
iverilog -g2012 -s tb_generic_crc_rx -o /tmp/ucie-rtl-tests/crc_rx rtl/crc16_ccitt.sv rtl/generic_crc_rx.sv tb/tb_generic_crc_rx.sv
vvp /tmp/ucie-rtl-tests/crc_rx
iverilog -g2012 -s tb_generic_replay_tx -o /tmp/ucie-rtl-tests/replay_tx rtl/crc16_ccitt.sv rtl/generic_replay_tx.sv tb/tb_generic_replay_tx.sv
vvp /tmp/ucie-rtl-tests/replay_tx
for profile in 48 64 32; do
  iverilog -g2012 -Ptb_reliable_stream_model.RATE_PROFILE_GT_S=${profile} -s tb_reliable_stream_model -o /tmp/ucie-rtl-tests/reliable_${profile} rtl/elastic_buffer.sv rtl/crc16_ccitt.sv rtl/credit_tx.sv rtl/link_manager.sv rtl/generic_replay_tx.sv rtl/generic_crc_rx.sv rtl/reliable_stream_model.sv tb/tb_reliable_stream_model.sv
  vvp /tmp/ucie-rtl-tests/reliable_${profile}
done
for profile in 48 64 32; do
  iverilog -g2012 -Ptb_profile_consistency.RATE_PROFILE_GT_S=${profile} -s tb_profile_consistency -o /tmp/ucie-rtl-tests/profile_consistency_${profile} rtl/elastic_buffer.sv rtl/crc16_ccitt.sv rtl/credit_tx.sv rtl/link_manager.sv rtl/generic_replay_tx.sv rtl/generic_crc_rx.sv rtl/stream_adapter.sv rtl/reliable_stream_model.sv tb/tb_profile_consistency.sv
  vvp /tmp/ucie-rtl-tests/profile_consistency_${profile}
done
for profile in 48 64; do
  iverilog -g2012 -Ptb_reliable_stream_random.RATE_PROFILE_GT_S=${profile} -s tb_reliable_stream_random -o /tmp/ucie-rtl-tests/reliable_random_${profile} rtl/elastic_buffer.sv rtl/crc16_ccitt.sv rtl/credit_tx.sv rtl/link_manager.sv rtl/generic_replay_tx.sv rtl/generic_crc_rx.sv rtl/reliable_stream_model.sv tb/tb_reliable_stream_random.sv
  vvp /tmp/ucie-rtl-tests/reliable_random_${profile}
done
```

Run generic synthesis and structural checks on the composed reliability model:

```sh
for profile in 48 64; do
  yosys -Q -p "read_verilog -sv rtl/elastic_buffer.sv rtl/crc16_ccitt.sv rtl/credit_tx.sv rtl/link_manager.sv rtl/generic_replay_tx.sv rtl/generic_crc_rx.sv rtl/reliable_stream_model.sv; chparam -set RATE_PROFILE_GT_S ${profile} reliable_stream_model; hierarchy -check -top reliable_stream_model; proc; opt; check; synth -top reliable_stream_model; check; stat"
done
```

Run the formal reference checks for the generic digital blocks:

```sh
formal/run_formal.sh
```

The buffer, credit counter, prototype link FSM, and generic replay sender pass Yosys SAT induction. The generic receive checker passes bounded model checking to depth 32; the composed stream-safety harness is bounded to depth 16. The script uses `async2sync` to model asynchronous-reset state at sampled clock edges; it does not verify reset pulse timing. None of these harnesses checks normative UCIe behavior.

Run generic Yosys elaboration, structural checks, and synthesis for the 48 and 64 GT/s digital profile configurations:

```sh
for profile in 48 64; do
  yosys -Q -p "read_verilog -sv rtl/elastic_buffer.sv rtl/credit_tx.sv rtl/stream_adapter.sv; chparam -set RATE_PROFILE_GT_S ${profile} stream_adapter; hierarchy -check -top stream_adapter; proc; opt; check; synth -top stream_adapter; check; stat"
done
```

## Verification record

| Evidence type | Result |
| --- | --- |
| RTL source change | Added compile-time 48/64 profile selection, unsupported-rate gating, link-down buffer retention, inactive-link credit-return suppression, and abstract lost-frame recovery injection |
| RTL simulation | PASS locally with Icarus Verilog 12.0 for both requested profiles, unsupported-rate rejection, link-down retention and credit gating, abstract lost-frame recovery, and smoke/stress benches; GitHub Actions #126 passed the complete suite |
| RTL reliability simulation | `tb_crc16_ccitt` PASS (CCITT-FALSE check value `0x29B1`); `tb_generic_crc_rx` PASS (duplicate suppressed, response/data retained during link-down, subsequent sequence delivered); `tb_reliable_stream_model` PASS at 48 and 64 profile labels (two-word ingress ordering, CRC error/NACK, retry after credit return, PHY-ready stall, output backpressure, reset/flush/fresh transfer, retry exhaustion, link recovery, accepted-frame loss and lost-ACK recovery, counter reset and saturation); unsupported profile 32 rejected |
| Profile configuration consistency | `tb_profile_consistency` PASS with Icarus Verilog 12.0 at 48 and 64: both layers report the same selected profile and transfer the same payload; profile 32 reports zero and disables both datapaths; included in hosted run #126 |
| Replay sender unit regression | `tb_generic_replay_tx` PASS locally with Icarus Verilog 12.0: wrong-sequence ACK ignored, responses gated while link inactive, frame content stable under replay backpressure, per-packet retry count boundaries checked, timeout event pulse checked, timeout pauses during link-down, exact active-cycle expiry checked, zero disables timeout, timeout exhaustion is fail-closed, and failure is sticky until reset |
| Recovery/credit boundary regression | `tb_link_manager` recovery fault-priority case and `tb_credit_tx_boundaries` PASS locally with Icarus Verilog 12.0 |
| Reset isolation regression | `tb_stream_reset` PASS locally for both 48 and 64 digital profiles; no handshakes during reset, pending-state flush, and fresh post-reset transfer verified |
| Randomized integrated datapath | `tb_stream_random` PASS at both profiles after inactive-link credit gating: 209 correctly ordered transactions each, with exact 2-bit credit-model accounting |
| Inactive-link credit handling | `tb_stream_rate_profile` PASS at 48/64 with credit pulses during link-down and at unsupported 32; credit count remains zero and later traffic remains credit-gated |
| Randomized reliability datapath | `tb_reliable_stream_random` PASS locally at both profile labels: 24 accepted/delivered transactions, six detected CRC errors retried successfully, two pending-frame link recoveries, and status counters match independent scoreboard counts; 338 model cycles per run |
| Generic synthesis | PASS locally and in GitHub Actions #126 with Yosys 0.33 at 48 and 64 profiles; `hierarchy -check`, pre/post-synthesis `check`, and generic `synth` completed without errors. No target library or timing constraints were used. |
| Reliability-model synthesis | PASS locally and in GitHub Actions #126 with Yosys 0.33 at 48 and 64 profile labels; hierarchy and structural checks clean, generic synthesis only |
| Formal verification | `formal/run_formal.sh` PASS locally and in GitHub Actions #126 with Yosys 0.33: five inductive block checks (buffer, credit transmitter, stream wrapper, prototype link manager, and replay sender with timeout-event pulse); RX reference BMC depth 32; composed accepted-to-delivered ordering/integrity BMC depth 16 including arbitrary accepted-frame drops. Reset is sampled after `async2sync`; bounded checks are not unbounded proofs, and none establish UCIe behavior. |
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
10. Installed Yosys 0.33 from the signed Ubuntu Noble archive and synthesized `stream_adapter` at 48 and 64 profile parameter values. Both runs pass hierarchy and structural checks and complete generic synthesis. Added the same checks to GitHub Actions and brought the existing randomized/stress elastic-buffer and CRC reference tests into that workflow.
11. Expanded the public-feature mapping against the UCIe Consortium's current UCIe 3.0 overview, labeling unimplemented features and normative details that remain unresolved.
12. Uploaded commit `124005a` to `feat/ucie-3-rate-profiles-20261014`; GitHub Actions run #112 completed successfully.
13. Added a project-defined stop-and-wait replay sender, RX CRC checker with duplicate suppression, and a single-clock loopback model connecting replay, generic credits, the project-local link manager, and abstract PHY-ready/error-injection inputs. The model keeps 48/64 as profile metadata and rejects unsupported profile labels.
14. Added RTL CRC known-answer, RX duplicate-suppression/retention, and profile-parameterized reliability tests. The reliability regression checks corrupted-frame drop/NACK, credit starvation, abstract PHY-ready backpressure, retransmission, RX output backpressure, link recovery retention, reset/flush/fresh transfer, retry exhaustion, and 32 GT/s profile rejection. Local Icarus runs pass at 48 and 64 and reject 32; Yosys 0.33 generic synthesis and structural checks pass for both supported profile labels.
15. Added the new regressions and both-profile reliability-model synthesis to GitHub Actions. The local full regression passes; hosted verification for this extension is recorded in item 20.
16. Added a distinct one-word ingress queue ahead of replay so one transaction can be buffered behind an outstanding retry-controlled transaction. Extended the 48/64 test to prove ordered delivery of two queued payloads; the profile runs pass.
17. Added a deterministic randomized reliability regression for both digital profile labels. Icarus Verilog 12.0 PASS: 24 transactions delivered in order at each profile, six injected CRC faults detected and retried, and two pending-frame link recoveries, with randomized PHY-ready, receiver-ready, and credit-return conditions (338 model cycles per run).
18. Added a standalone replay-sender regression for wrong-sequence ACKs, response gating during link-down, stable frame contents under backpressure, per-packet retry-count limits, and sticky fail-closed exhaustion. Icarus Verilog 12.0 PASS; CI and traceability entries added. These assertions define project-model behavior only.
19. Ran the complete RTL smoke workflow locally after these changes: all directed, randomized, stress, profile, reset, recovery, CRC, and replay simulations passed; both `stream_adapter` and `reliable_stream_model` completed Yosys 0.33 generic synthesis and structural checks at 48 and 64; unsupported 32 profile was rejected. Workflow YAML parsing and `git diff --check` passed. No formal, target-library timing, PHY, electrical, hardware, or interoperability evidence was produced.
20. Uploaded commit `3666557` to `feat/ucie-3-rate-profiles-20261014`; GitHub Actions run #116 completed successfully, including the new replay-sender and randomized reliability tests. This remains digital-only evidence.
21. Added five Yosys SAT harnesses and a repeatable `formal/run_formal.sh`. Local Yosys 0.33 PASS: four inductive reference checks (buffer, credit TX, prototype link FSM, replay TX) and an RX bounded proof to depth 8. The asynchronous reset is transformed with `async2sync`, and the RX result is explicitly bounded; these are generic digital contracts only. Added the proof run to CI; hosted result pending.
22. Extended the 48/64 randomized reliability test with two deterministic fault/recovery events while accepted frames are held before the abstract channel. Both profile runs pass with 24 ordered deliveries, six CRC retries, and two recoveries in 338 model cycles.
23. Extended `tb_reliable_stream_model` at both supported profile labels with a fault on the sampled abstract-channel frame-acceptance edge. The regression proves the RX response and user payload remain pending while link-down, the ACK retires replay after recovery, and the payload is delivered once; 48, 64, and unsupported 32 profile runs pass with Icarus Verilog 12.0.
24. Added project-defined response timeout to the stop-and-wait replay sender. The timer counts active-link model clocks, pauses during link-down, and retries or fails at its configured boundary; zero disables the timer. Added `drop_response_i` as a digital test hook, a lost-ACK end-to-end test at 48/64, exact timeout/pause/disable/exhaustion unit cases, and timeout-aware SAT reference behavior. Icarus Verilog 12.0 directed and randomized reliability tests pass for both profiles, unsupported profile 32 remains rejected, Yosys 0.33 generic synthesis passes for both profile labels, and all five formal checks pass locally (replay TX inductive; CRC RX bounded to depth 8). GitHub Actions run #120 passed this timeout extension. The timeout is project-defined and has no conversion to GT/s or UCIe timing.
25. Added project-defined saturating CRC-error, response-timeout, and link-recovery counters. The directed profile regression checks event counts, reset clearing, and saturation with a narrow test-only counter width; randomized tests compare the counters against independent scoreboards at 48/64. Formal replay TX checks the timeout event pulse against its reference model. Local directed/randomized simulations, Yosys 0.33 synthesis at both profile labels, and all five then-configured formal checks pass; GitHub Actions run #121 passed. Counters are project telemetry and do not represent standard UCIe status fields.
26. Added an end-to-end formal safety harness for the composed single-clock reliability model. Yosys 0.33 bounded SAT passes through 16 cycles with arbitrary credit returns, backpressure, CRC faults, dropped responses, link faults and reset, checking that delivered data matches accepted source order. This does not prove liveness, UCIe conformance, or operation beyond the checked bound. GitHub Actions run #122 passed.
27. Extended the generic CRC receiver bounded SAT reference check from depth 8 to 32 after local Yosys 0.33 runs at depths 12, 16, and 32 passed. This is still a bounded result, not induction. GitHub Actions run #123 passed the depth-32 check.
28. Ran the complete formal script with the 32-cycle RX bound and 16-cycle composed bound. All four inductive checks and both bounded checks pass locally with Yosys 0.33. The composed check needed a 60-second local solver budget after one run exceeded 30 seconds. GitHub Actions runs #122 and #123 passed the composed proof; #123 passed the updated RX bound too.
29. Added `tb_profile_consistency` to check `stream_adapter` and `reliable_stream_model` together. It verifies equal effective profile reporting and transfers the same payload through both for 48 and 64; unsupported 32 reports zero and blocks both. The shared-profile regression and directed reliability tests pass locally with Icarus Verilog 12.0; GitHub Actions run #124 passed.
30. Added `drop_frame_i`, a test-only abstract-channel fault that consumes a credit but removes the frame before RX. At both 48/64 profile labels, the directed regression confirms no RX data/response, timeout, fresh-credit gating, retry, and one delivery. Local Icarus Verilog 12.0 tests, all six formal checks, and Yosys 0.33 generic synthesis pass at 48/64. GitHub Actions run #125 passed this full change set. This hook is not a physical fault or UCIe-defined behavior.
31. Fixed the stream wrapper to ignore returned-credit pulses while reset, link-down, or unsupported. Directed profile tests exercise link-down pulses at 48/64 and an unsupported-profile pulse at 32; deterministic randomized runs pass with exact scoreboard accounting and 209 delivered transactions per supported profile. The standalone link-hold bench now grants its initial credit only after link-up. Focused local tests and GitHub Actions run #125 pass. This matches the reliability model's active-link gating and is a project-local policy, pending normative credit rules.
32. Added `formal_stream_adapter`, an independent reference harness for wrapper buffering and credit accounting. It checks active-link-only credit returns, equivalent 48/64 digital datapaths and rate outputs, and fail-closed 32 behavior. The inductive Yosys 0.33 proof passes locally and in GitHub Actions run #126 as part of the seven-check `formal/run_formal.sh` suite.

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

### Exact local commands for accepted-frame loss and inactive-credit checks

```sh
for profile in 48 64; do
  iverilog -g2012 -Wall -Ptb_reliable_stream_model.RATE_PROFILE_GT_S=$profile -s tb_reliable_stream_model -o /tmp/tb_reliable_stream_model_$profile rtl/elastic_buffer.sv rtl/crc16_ccitt.sv rtl/credit_tx.sv rtl/link_manager.sv rtl/generic_replay_tx.sv rtl/generic_crc_rx.sv rtl/reliable_stream_model.sv tb/tb_reliable_stream_model.sv
  vvp /tmp/tb_reliable_stream_model_$profile
done
for profile in 48 64 32; do
  iverilog -g2012 -Wall -Ptb_stream_rate_profile.RATE_PROFILE_GT_S=$profile -s tb_stream_rate_profile -o /tmp/tb_stream_rate_profile_$profile rtl/elastic_buffer.sv rtl/credit_tx.sv rtl/stream_adapter.sv tb/tb_stream_rate_profile.sv
  vvp /tmp/tb_stream_rate_profile_$profile
done
for profile in 48 64; do
  iverilog -g2012 -Wall -Ptb_stream_random.RATE_PROFILE_GT_S=$profile -s tb_stream_random -o /tmp/tb_stream_random_$profile rtl/elastic_buffer.sv rtl/credit_tx.sv rtl/stream_adapter.sv tb/tb_stream_random.sv
  vvp /tmp/tb_stream_random_$profile
done
formal/run_formal.sh
```

Observed results: directed reliability passes at 48 and 64; shared-profile tests pass at 48/64 and reject 32; stream-profile tests pass at 48/64 and reject 32; randomized stream passes with 209 ordered deliveries per supported profile; all seven current formal checks pass locally and in GitHub Actions #126, including the wrapper induction and depth-16 composed proof with arbitrary frame loss. Yosys 0.33 generic reliability synthesis passed at both 48 and 64.
