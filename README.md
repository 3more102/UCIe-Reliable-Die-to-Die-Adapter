# Reliable UCIe Die-to-Die Adapter

Graduation research project: **Design and UVM-Based Verification of a Reliable UCIe Die-to-Die Adapter for Chiplet-Based Systems**.

## Status
Generic, single-clock digital prototype. **Not a UCIe-compliant implementation.** It contains a ready/valid elastic buffer, generic credit transmitter, project-local link manager, streaming integration, and generic CRC-16 infrastructure. UCIe version, flit formats, state transitions, retry semantics, PHY interface and interoperability must be derived from the complete normative specification before compliance can be claimed. No PHY or electrical link is implemented.

## Current contents
- Parameterized, ready/valid elastic buffer and credit-gated TX in synthesizable SystemVerilog
- Project-local link manager and generic stream integration
- SystemVerilog directed and stress regressions, plus independent generic CRC reference tests
- Architecture and verification plan
- UVM agent/scoreboard to be added after interface and protocol requirements are frozen

## Run
```sh
iverilog -g2012 -s tb_elastic_buffer -o simv rtl/elastic_buffer.sv tb/tb_elastic_buffer.sv
vvp simv
```

## Source
UCIe Consortium: https://www.uciexpress.org/

## UCIe 3.0 rate-profile work
The streaming demonstrator has compile-time digital profile selections for 48 and 64 GT/s. These selections do not model a PHY clock or demonstrate electrical operation at either rate. See [the rate-profile capability matrix and verification record](docs/UCIe_3_RATE_PROFILES.md).
