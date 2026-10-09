# Architecture baseline — pre-specification prototype

This repository currently implements generic infrastructure primitives, **not a UCIe adapter**.

## Planned partition
- Protocol-facing interface: packet/flit ingress and egress, mode selection.
- TX pipeline: buffering, formatting, optional integrity protection, credit accounting.
- RX pipeline: alignment, integrity checks, receive buffering, acknowledgement/recovery.
- Link manager: reset, training, operational states, fault handling.
- PHY abstraction: implementation-specific lane, clock and sideband interfaces.

## Open specification decisions
1. Normative UCIe revision and access to its complete specification.
2. Supported stack: raw streaming versus PCIe/CXL/other protocol-layer integration.
3. Link width, frequency, PHY type, clock domains, and operating modes.
4. Precise CRC polynomial, coverage, ordering and retry protocol.
5. Credits: initialization, return signaling, overflow/underflow and reset semantics.
6. Compliance criteria and interoperability testing.

Do not infer UCIe compliance from the generic blocks in rtl/.
