# Elastic buffer verification contract

This milestone covers a generic ready/valid elastic buffer, **not** UCIe protocol conformance.

## Required invariants

1. Input transfer occurs only on `in_valid && in_ready`.
2. Output transfer occurs only on `out_valid && out_ready`.
3. If `out_valid && !out_ready`, output valid and data remain stable until accepted or reset.
4. No accepted transaction may be lost, duplicated, or reordered.
5. Reset discards all outstanding buffered transactions and deasserts output valid.
6. Test empty-to-full transitions, simultaneous enqueue/dequeue, sustained backpressure, and reset while occupied.
7. Verify parameter configurations at multiple widths and depths, including depth one where supported.
8. Track accepted-input and accepted-output counts; on drain, counts and ordered payloads must match.

## Directed regression gate

```sh
iverilog -g2012 -s tb_elastic_buffer -o simv rtl/elastic_buffer.sv tb/tb_elastic_buffer.sv
vvp simv
```

This command is a documented intended check, not evidence that CI or simulation has passed.

## Follow-on integration

Do not port retry/CRC logic from the separate ChipletLink repository without first reviewing licensing, module interfaces, reset conventions, sequence-space handling, scoreboard assumptions, and tests. Keep educational protocol abstractions distinct from normative UCIe requirements.
