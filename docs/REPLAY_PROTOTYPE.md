# Experimental single-entry replay slot

The stop-and-wait `replay_slot` retains one payload while awaiting explicit acknowledgment. On `retry_req`, it schedules retransmission of the same stored payload. The upstream interface is blocked until ACK. ACK has priority over retry when both are asserted.

This is **not** a UCIe retry controller: it has no sequence IDs, flit framing, timeout, replay window, replay-depth negotiation, retry handshake, credit accounting, reset/retrain policy, or normative error signaling. Do not infer protocol conformance or throughput from its directed smoke test.
