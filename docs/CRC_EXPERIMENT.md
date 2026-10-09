# Experimental integrity primitive

`rtl/crc16_ccitt.sv` computes CRC-16/CCITT-FALSE over a parameterized fixed-width word, processing its most significant bit first.

- Polynomial: 0x1021
- Initialization: 0xFFFF
- Reflected input/output: false
- Final XOR: 0
- Reference vector: ASCII `123456789` gives 0x29B1.

This is a **generic experimental building block**, not a UCIe CRC definition. Do not integrate it into normative flit framing without selecting and verifying the appropriate UCIe revision and mode. It does not implement retry, sequence tracking, or link recovery.
