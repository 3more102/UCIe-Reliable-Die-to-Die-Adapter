# UVM environment plan

Target layout:
- agents/tx_agent.sv and agents/rx_agent.sv
- sequences/reset_traffic_seq.sv and sequences/error_injection_seq.sv
- env/adapter_env.sv, env/adapter_scoreboard.sv
- tests/adapter_base_test.sv
- coverage/adapter_coverage.sv

Build the UVM environment only after the interfaces and transaction contract are frozen against the selected normative UCIe specification. Until then, the directed RTL tests under tb/ exercise generic infrastructure primitives.
