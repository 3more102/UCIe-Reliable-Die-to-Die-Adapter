# Specification gate — selected UCIe 3.0 profile

**State (2026-10-21): OPEN. No adapter compliance claim.**

Primary normative source: https://www.uciexpress.org/specifications (full specification distributed by request).

Candidate: UCIe 3.0 Standard 2D, protocol/format TBD. FDI-focused integration is a *design preference*, not a selected signal contract.

| ID | Topic | Evidence required to close | Owning workstream | Acceptance test | Status |
|---|---|---|---|---|---|
| SPEC-01 | Exact rev/profile/protocol and format | authorized revision and configuration section | Architecture | written profile decision | BLOCKED |
| SPEC-02 | FDI signal names/timing | normative interface timing, resets and direction | RTL TX/RX | port-level directed/SVA checks | BLOCKED |
| SPEC-03 | RDI PHY abstraction | normative minimum required digital signals and state | Link | active/reset/recovery transitions | BLOCKED |
| SPEC-04 | Flit layout | selected format fields and bit numbering | RTL TX/RX | golden format vectors | BLOCKED |
| SPEC-05 | CRC definition | polynomial, initialization, bit/byte ordering, covered bytes | RTL integrity | independent golden vectors | BLOCKED |
| SPEC-06 | Retry and replay semantics | applicability, ACK/NACK, sequence and storage rules | Reliability | fault-response scoreboard | BLOCKED |
| SPEC-07 | Flow control and ordering | documented ownership and state | RTL/verification | backpressure, boundary, ordering | BLOCKED |
| SPEC-08 | Recovery failure semantics | legal recovery and unrecoverable transitions | RTL/verification | timeout and fault policy checks | BLOCKED |

The isolated experimental stop-and-wait module is outside this requirements traceability. It can only satisfy generic infrastructure milestones.

## Precise engineering priority
1. Request or provide the full UCIe 3.0 specification and settle profile/format.
2. Record full section references and signal definitions above.
3. Define FDI-first pin-accurate adapter boundary with limitations.
4. Implement a standards-specific top separately and keep non-compliant experimental transport isolated.
5. Use an independent scoreboard, and obtain genuine simulation evidence.
