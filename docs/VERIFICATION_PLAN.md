# Verification plan (draft)

## Phase 0 — Infrastructure
Verify elastic-buffer reset, push, pop, full-throughput simultaneous push/pop, backpressure, and random transaction preservation.

## Phase 1 — Requirements baseline
Select UCIe revision and supported link modes. Build a requirement-to-test traceability matrix using official normative documents. Define PHY-facing contract and protocol-layer contract.

## Phase 2 — UVM environment
Create independent TX/RX agents, sequencers, monitors, transaction scoreboard, functional coverage and assertions. Randomize reset, traffic, credit availability, and error conditions.

## Phase 3 — Reliability
Implement and verify only specification-supported CRC, retry, replay, link recovery and error-reporting behavior. Measure detection latency, recovery time and data integrity.

### Generic digital model available before specification access
`generic_replay_tx`, `generic_crc_rx`, and `reliable_stream_model` provide a project-defined stop-and-wait CRC/replay loopback for digital testing. Directed and deterministic randomized tests cover corruption/NACK, duplicate suppression, wrong-sequence response rejection, retry limit, credit starvation, abstract PHY-ready backpressure, output backpressure, and link recovery at the 48 and 64 GT/s profile labels. This is infrastructure evidence only. Its CRC/frame format, sequence convention, credit semantics, retry policy and state behavior must not be treated as UCIe requirements.

## Exit criteria
All required assertions pass, no scoreboard mismatches, target coverage met, and documented known limitations. No UCIe compliance claim without normative conformance and interoperability evidence.
