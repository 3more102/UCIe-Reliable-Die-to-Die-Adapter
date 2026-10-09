# Known limitations and release gates

- **Not UCIe compliant:** no normative protocol framing, sideband, PHY or training implementation.
- **Credit transmitter:** single-cycle credit-return pulse; saturation drops excess returns. No specification-derived credit accounting or replay.
- **Link interruption:** generic streaming adapter retains its one buffered beat when link goes down; no guaranteed remote delivery or retry.
- **Reset:** resets buffered traffic and credits; in-flight traffic is not preserved.
- **UVM:** no executable UVM environment yet.
- **Verification:** CI status must be checked independently; testbench creation is not proof of test passage.
- **CDC/RDC, PPA, formal, FPGA:** not qualified.
- **Research:** no validated novelty or experimental comparison.

Release remains **HOLD** until selected scope and evidence are complete.
