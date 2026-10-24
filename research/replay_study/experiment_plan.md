# Replay-buffer depth versus hardware cost — research plan

Status: **PLANNED, UNMEASURED**. The current experimental stop-and-wait transport retains one payload. It is not a normative UCIe retry buffer and is not eligible for claims about UCIe replay-depth behavior.

## Research feasibility gate
Investigate selected UCIe 3.0 Standard 2D protocol/format and retry applicability from authorized normative material. Confirm buffer ownership, outstanding-window limits, ACK/NACK/sequence constraints, recovery events, and ability to vary storage size. If invalid, label results as an **experimental non-compliant extension**, or change the study question.

## Hypotheses to test, not assume
- H1: Storage capacity and metadata increase with buffer depth, but mapping (flops vs macro) changes the area slope.
- H2: Buffer depth changes backpressure or unrecoverable events only in regimes where outstanding-data retention limits become binding.
- H3: Beyond an application- and link-dependent operating point, larger buffers provide diminishing throughput/recovery benefit.

## Controlled experiment matrix
| Factor | Preliminary settings (non-normative) | Control |
|---|---|---|
| Payload storage | 256 B, 512 B, 1 KiB, 2 KiB, 4 KiB | same data and metadata format |
| Offered load | 25%, 50%, 75%, 95% | same transaction traces |
| Link delay | short, medium, long (state cycles exactly) | clock fixed |
| Faults | none, one, burst, stochastic | same independent seeds |
| Downstream stall | none, periodic, random | reproducible schedule |

Run baseline first, vary one factor at a time, then run only justified interaction crosses. Log every pass, fail, timeout, and skip. Fault probabilities in an abstract model are **not physical BER measurements**.

## Output columns
`git_sha,model_revision,tool_version,profile,buffer_bytes,actual_storage_bits,seed,load,link_delay_cycles,fault_model,fault_count,transfer_count,delivered_count,crc_errors,replays,stall_cycles,recovery_latency_cycles,unrecoverable_events,pass_fail,timeout,cell_area_um2,ff_count,critical_delay_ns,memory_mapping`.

## Analysis / statistics
- Throughput = delivered useful bits / measured elapsed cycles (with explicitly stated clock assumptions).
- Recovery latency = cycles between first fault observation and defined restoration of normal progress.
- Area includes payload bits, metadata, muxing and control.
- Compute distributions over independent seeds and confidence intervals where appropriate.
- No pseudo-precision, invented curves, or zero-failure guarantees.
- Keep PDK, liberty, synthesis tool, constraints, and clock constant during area/timing comparisons.

## Evidence ladder
1. UCIe mode rules confirmed, with citations.
2. Parameterized storage passes isolated tests and independent reference checking.
3. Integrated recovery tests pass with multiple depths.
4. Mapped synthesis uses the same technology assumptions.
5. OpenROAD places/routes viable configurations and produces reports.
6. Only then prepare a paper claim and compare with prior work.

Primary resources: https://www.uciexpress.org/specifications , https://openroad.org/ and https://github.com/The-OpenROAD-Project/OpenROAD-flow-scripts
