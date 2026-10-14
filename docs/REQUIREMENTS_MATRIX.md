# Requirements traceability (initial)

| ID | Requirement | Verification | Status |
| --- | --- | --- | --- |
| INF-001 | Elastic buffer holds data while stalled | tb_elastic_buffer | PASS locally; CI unconfirmed |
| INF-002 | No credit means no TX transfer | tb_credit_tx | PASS locally; CI unconfirmed |
| INF-003 | Link state deasserts up during fault recovery and recovery does not restart training while the fault remains asserted | tb_link_manager | PASS locally; CI unconfirmed |
| INF-004 | Generic credit counter saturates, does not underflow, and preserves stalled data | tb_credit_tx_boundaries | PASS locally; CI unconfirmed |
| INF-005 | Stream interfaces quiesce during reset, pending state clears, and fresh traffic works after reset | tb_stream_reset at 48 and 64 profiles | PASS locally; CI unconfirmed |
| SPEC-001 | Select official UCIe revision and profile | Specification review | Open |
| SPEC-002 | Normative flit and sideband encoding | UVM reference model | Open |
| SPEC-003 | Normative retry, CRC and credit semantics | Fault injection | Open |
| SPEC-004 | PHY electrical and interoperability qualification | External evidence | Open |
| PROFILE-001 | Configure the digital model for 48 GT/s or 64 GT/s | `tb_stream_rate_profile` compiled once per rate | PASS locally at 48 and 64 GT/s; digital model only |
| PROFILE-002 | Reject unsupported configured rates and retain data while link is down | `tb_stream_rate_profile` (32 GT/s case) and `tb_stream_link_hold` | PASS locally; unsupported profile rejected and pending word preserved |

Rate-profile behavior, clock-model limits, capability evidence, and next actions are recorded in [UCIe 3.0 rate profiles](UCIe_3_RATE_PROFILES.md). This matrix does not assert UCIe compliance or physical line-rate operation.

This matrix does not assert UCIe compliance.
