"""Independent generic CRC-16 reference tests (not a UCIe CRC definition)."""
import random
import unittest

def crc16_bits(data: int, width: int, polynomial: int, init: int = 0) -> int:
    """MSB-first, non-reflected CRC with no final XOR."""
    if width < 0 or data < 0 or data >= (1 << width):
        raise ValueError("invalid data or width")
    if not 0 <= polynomial <= 0xFFFF or not 0 <= init <= 0xFFFF:
        raise ValueError("CRC parameters must be 16-bit")
    crc = init
    for shift in range(width - 1, -1, -1):
        feedback = ((crc >> 15) ^ ((data >> shift) & 1)) & 1
        crc = (crc << 1) & 0xFFFF
        if feedback:
            crc ^= polynomial
    return crc

class TestCrcReference(unittest.TestCase):
    def test_ccitt_false_check_vector(self):
        # CRC-16/CCITT-FALSE: poly 0x1021, init 0xFFFF, no reflection/xorout.
        payload = b"123456789"
        value = int.from_bytes(payload, "big")
        self.assertEqual(crc16_bits(value, 8 * len(payload), 0x1021, 0xFFFF), 0x29B1)

    def test_streaming_partition_invariance(self):
        rng = random.Random(0xC1E)
        for _ in range(1000):
            width = rng.randint(1, 256)
            split = rng.randint(0, width)
            data = rng.getrandbits(width)
            polynomial = rng.getrandbits(16)
            init = rng.getrandbits(16)
            whole = crc16_bits(data, width, polynomial, init)
            prefix = data >> (width - split)
            suffix = data & ((1 << (width - split)) - 1)
            first = crc16_bits(prefix, split, polynomial, init)
            streamed = crc16_bits(suffix, width - split, polynomial, first)
            self.assertEqual(whole, streamed)

    def test_reject_invalid_inputs(self):
        for args in [(-1, 8, 0x1021), (256, 8, 0x1021), (0, -1, 0x1021),
                     (0, 8, 0x10000), (0, 8, 0x1021, -1)]:
            with self.assertRaises(ValueError):
                crc16_bits(*args)

if __name__ == "__main__":
    unittest.main()
