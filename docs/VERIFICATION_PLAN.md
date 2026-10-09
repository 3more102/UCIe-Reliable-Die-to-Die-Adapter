# Verification plan (draft)

## Phase 0 — Infrastructure
Verify elastic-buffer reset, push, pop, full-throughput simultaneous push/pop, backpressure, and random transaction preservation.

## Phase 1 — Requirements baseline
Select UCIe revision and supported link modes. Build a requirement-to-test traceability matrix using official normative documents. Define PHY-facing contract and protocol-layer contract.

## Phase 2 — UVM environment
Create independent TX/RX agents, sequencers, monitors, transaction scoreboard, functional coverage and assertions. Randomize reset, traffic, credit availability, and error conditions.

## Phase 3 — Reliability
Implement and verify only specification-supported CRC, retry, replay, link recovery and error-reporting behavior. Measure detection latency, recovery time and data integrity.

## Exit criteria
All required assertions pass, no scoreboard mismatches, target coverage met, and documented known limitations. No UCIe compliance claim without normative conformance and interoperability evidence.
