# Verification gates and current scope

## Executable open-source regression
- Elastic buffer smoke and sustained throughput
- Credit-gated TX smoke
- Prototype link manager smoke
- Streaming link-down data retention
- CRC-16/CCITT-FALSE check vector and corruption detection

These tests cover *generic prototype primitives* only.

## Next release gates
1. Fix selected UCIe revision/profile and obtain the complete normative specification.
2. Define PHY, adapter, sideband, framing and flow-control requirements.
3. Build a spec-grounded TX/RX integration test with independently checked reference model.
4. Implement UVM agents, scoreboard, functional coverage and fault-injection sequences.
5. Execute commercial UVM regression and document simulator/version/seed.
6. Perform CDC/RDC, formal and synthesis qualification.
7. Demonstrate bidirectional two-chiplet operation and report measured metrics.

Do not infer protocol compliance or hardware qualification from the open-source smoke tests.
