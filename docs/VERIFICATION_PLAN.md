# Verification plan (draft)

## Phase 0 — Infrastructure
Verify elastic-buffer reset, push, pop, full-throughput simultaneous push/pop, backpressure, and random transaction preservation.

## Phase 1 — Requirements baseline
Select UCIe revision and supported link modes. Build a requirement-to-test traceability matrix using official normative documents. Define PHY-facing contract and protocol-layer contract.

## Phase 2 — UVM environment
Create independent TX/RX agents, sequencers, monitors, transaction scoreboard, functional coverage and assertions. Randomize reset, traffic, credit availability, and error conditions.

## Phase 3 — Reliability
Implement and verify only specification-supported CRC, retry, replay, link recovery and error-reporting behavior. Measure detection latency, recovery time and data integrity.

## Phase 4 — Formal digital checks
`formal/run_formal.sh` uses Yosys SAT to compare the generic buffer, credit TX, stream adapter wrapper, prototype link FSM, and stop-and-wait replay TX against independent reference models. These five inductive checks establish only project-defined sampled-cycle RTL contracts. The wrapper proof includes active-link credit gating, 48/64 datapath equivalence, and unsupported 32 rejection. The generic CRC RX reference is checked by bounded model checking to depth 32; it is not reported as an unbounded proof. A composed safety harness checks accepted-to-delivered payload order and integrity for 16 cycles under arbitrary sampled stalls, credit returns, CRC faults, accepted-frame loss, response loss, link faults, and reset. This is bounded safety, not liveness. `async2sync` converts asynchronous reset cells for clock-sampled proof, so these results do not verify analog reset pulse widths or asynchronous timing.

### Generic digital model available before specification access
`generic_replay_tx`, `generic_crc_rx`, and `reliable_stream_model` provide a project-defined stop-and-wait CRC/replay loopback for digital testing. Directed and deterministic randomized tests cover corruption/NACK, an accepted abstract frame dropped before RX, a lost ACK, timeout and replay, duplicate suppression, wrong-sequence response rejection, retry limit, credit starvation, abstract PHY-ready backpressure, output backpressure, and link recovery at the 48 and 64 GT/s profile labels. The directed frame-drop case checks that the lost attempt consumes one abstract credit, exposes no RX data or response, times out, waits for another credit, and delivers once after retry. Saturating CRC-error, response-timeout, and link-recovery counters are checked against directed expected counts and randomized scoreboards, including reset and saturation. The timeout is parameterized in active-link model cycles and pauses while the link is down; it is not derived from GT/s or UCIe timing. This is infrastructure evidence only. Its CRC/frame format, sequence convention, credit semantics, timeout, retry policy, status counters and state behavior must not be treated as UCIe requirements.

## Exit criteria
All required assertions pass, no scoreboard mismatches, target coverage met, and documented known limitations. No UCIe compliance claim without normative conformance and interoperability evidence.
