# Requirements traceability (initial)

| ID | Requirement | Verification | Status |
| --- | --- | --- | --- |
| INF-001 | Elastic buffer holds data while stalled | tb_elastic_buffer | PASS locally and GitHub Actions run #112 |
| INF-002 | No credit means no TX transfer | tb_credit_tx | PASS locally and GitHub Actions run #112 |
| INF-003 | Link state deasserts up during fault recovery and recovery does not restart training while the fault remains asserted | tb_link_manager | PASS locally and GitHub Actions run #112 |
| INF-004 | Generic credit counter saturates, does not underflow, and preserves stalled data | tb_credit_tx_boundaries | PASS locally and GitHub Actions run #112 |
| INF-005 | Stream interfaces quiesce during reset, pending state clears, and fresh traffic works after reset | tb_stream_reset at 48 and 64 profiles | PASS locally and GitHub Actions run #112 |
| INF-006 | Integrated adapter preserves transaction ordering and exact generic credit accounting under randomized link/backpressure traffic | tb_stream_random at 48 and 64 profiles | PASS locally and GitHub Actions run #112 |
| INF-007 | Streaming integration elaborates and synthesizes without structural errors for both supported digital profiles | Yosys 0.33 `hierarchy -check`, `check`, `synth`, `check` at 48 and 64 | PASS locally and GitHub Actions run #112; generic synthesis only |
| INF-008 | Generic replay sender retries a CRC-rejected packet, preserves queued order, holds for credit/backpressure, retains pending data across project-local link recovery, resets cleanly, and fails after its retry limit | `tb_reliable_stream_model` at 48 and 64 profiles | PASS locally with Icarus Verilog 12.0; project-defined protocol only |
| INF-009 | Generic receiver ACKs but suppresses a duplicate sequence without redelivery | `tb_generic_crc_rx` | PASS locally with Icarus Verilog 12.0; one-bit sequence convention is project-defined |
| INF-010 | RTL CRC implementation matches the CCITT-FALSE check value for ASCII `123456789` | `tb_crc16_ccitt` | PASS locally with Icarus Verilog 12.0; generic CRC only |
| INF-011 | Generic reliability model elaborates and synthesizes structurally for both digital profile labels | Yosys 0.33 `hierarchy -check`, `check`, `synth`, `check` at 48 and 64 | PASS locally; generic synthesis only |
| SPEC-001 | Select official UCIe revision and profile | Specification review | Open |
| SPEC-002 | Normative flit and sideband encoding | UVM reference model | Open |
| SPEC-003 | Normative retry, CRC and credit semantics | Fault injection | Open |
| SPEC-004 | PHY electrical and interoperability qualification | External evidence | Open |
| PROFILE-001 | Configure the digital model for 48 GT/s or 64 GT/s | `tb_stream_rate_profile` compiled once per rate; Yosys elaboration and synthesis at each rate | PASS locally and GitHub Actions run #112 at both rates; digital model only |
| PROFILE-002 | Reject unsupported configured rates and retain data while link is down | `tb_stream_rate_profile` (32 GT/s case) and `tb_stream_link_hold` | PASS locally and GitHub Actions run #112; unsupported profile rejected and pending word preserved |

Rate-profile behavior, clock-model limits, capability evidence, and next actions are recorded in [UCIe 3.0 rate profiles](UCIe_3_RATE_PROFILES.md). This matrix does not assert UCIe compliance or physical line-rate operation.

This matrix does not assert UCIe compliance.
