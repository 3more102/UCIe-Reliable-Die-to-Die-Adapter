# Reliable UCIe Die-to-Die Adapter

Graduation research project: **Design and UVM-Based Verification of a Reliable UCIe Die-to-Die Adapter for Chiplet-Based Systems**.

## Status
Initial engineering scaffold. **Not a UCIe-compliant implementation.** UCIe version, flit formats, state transitions, retry semantics, PHY interface and interoperability must be derived from the licensed/official specification before compliance can be claimed.

## Initial milestone
- Parameterized, ready/valid elastic buffer in synthesizable SystemVerilog
- Cocotb-independent SystemVerilog directed smoke test
- Architecture and verification plan
- UVM agent/scoreboard to be added after interface and protocol requirements are frozen

## Run
```sh
iverilog -g2012 -s tb_elastic_buffer -o simv rtl/elastic_buffer.sv tb/tb_elastic_buffer.sv
vvp simv
```

## Source
UCIe Consortium: https://www.uciexpress.org/
