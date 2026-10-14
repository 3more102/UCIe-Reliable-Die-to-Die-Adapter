# Architecture — generic pre-specification prototype

This repository implements generic infrastructure and a project-defined digital reliability model, **not a UCIe adapter**. The full normative UCIe specification and a PHY contract are not present in the repository.

## Current digital partition

| Layer | RTL | Current behavior and evidence | Boundary / unresolved item |
| --- | --- | --- | --- |
| Protocol-facing stream | `stream_adapter`, `elastic_buffer` | Generic ready/valid word buffering; 48/64 profile selection; reset and link-down gating | No UCIe flit format, protocol mapping, or mode selection |
| TX reliability | `elastic_buffer`, `generic_replay_tx`, `crc16_ccitt` | One queued ingress word plus one outstanding replay word; one-bit sequence; CCITT-FALSE CRC over sequence plus payload; sends again on NACK up to `MAX_RETRIES` | All formats and retry policy here are project-defined, not UCIe-defined |
| Flow control | `credit_tx` | Bounded generic credit counter; one credit per accepted abstract channel attempt | Credit units, initialization, return rules, and reset semantics are unresolved normative work |
| RX reliability | `generic_crc_rx` | CRC validation, one-entry receive holding register, ACK/NACK response, duplicate suppression | No UCIe CRC coverage, sequence field, response encoding, or replay rules |
| Link control | `link_manager` | Project-local DOWN/TRAINING/ACTIVE/RECOVERY states and fault recovery input | These are not normative UCIe state names or timing |
| PHY boundary | `reliable_stream_model` inputs `phy_ready_i`, `corrupt_crc_i` | Single-clock abstract ready signal and digital CRC-bit fault injection | No lane, serializer/deserializer, PHY clock, electrical channel, timing, or sideband pins |

## Project-defined reliability model

`reliable_stream_model` connects the blocks above into a digital loopback for testing. The source first enters a one-word ingress elastic buffer, then the replay sender can hold one outstanding payload while the ingress buffer holds the next. A transmitted frame is represented internally as `{sequence_bit, CRC-16, payload}`. The receiver checks the CRC, holds a valid payload until the output accepts it, and acknowledges a repeated valid sequence without delivering it again. A bad CRC produces a one-cycle error indication and a NACK; each attempt consumes one generic credit at the abstract channel handshake. The default retry limit is two retransmissions after the first attempt, after which the sender remains failed until reset. Link loss holds the pending transmission and response state through project-local recovery.

The CRC is the generic CCITT-FALSE function already in `crc16_ccitt.sv` (polynomial `0x1021`, initial remainder `0xFFFF`, no reflection, xorout `0`). The one-bit sequence, frame concatenation/order, ACK/NACK behavior, credit accounting, retry limit, and recovery retention are project choices. They are not presented as UCIe encodings or requirements. The 48/64 profile parameter is configuration metadata only and does not change the modeled clock or rate.

## Remaining layers and specification decisions

The protocol-facing UCIe framing/mapping, sideband and management transport, normative initialization and state machine, normative integrity/retry/credit behavior, lane alignment, and PHY implementation remain unimplemented. Before implementing those behaviors, select the UCIe revision and obtain the corresponding full specification. Also define link width, PHY type, clocking/CDC boundaries, and compliance evidence. Do not infer compliance from the generic model or its tests.

## Open specification decisions
1. Normative UCIe revision and access to its complete specification.
2. Supported stack: raw streaming versus PCIe/CXL/other protocol-layer integration.
3. Link width, frequency, PHY type, clock domains, and operating modes.
4. Precise CRC polynomial, coverage, ordering and retry protocol.
5. Credits: initialization, return signaling, overflow/underflow and reset semantics.
6. Compliance criteria and interoperability testing.

Do not infer UCIe compliance from the generic blocks in rtl/.
