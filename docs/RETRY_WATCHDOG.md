# Experimental retry timeout watchdog

The watchdog counts cycles with `outstanding=1`, resetting on `progress` and producing a single-cycle pulse at a configured interval. The counter then restarts if outstanding remains asserted.

Constraints: `TIMEOUT_CYCLES >= 1` and `TIMEOUT_CYCLES <= 2**COUNTER_WIDTH`. Configuration is currently assumed valid, not statically checked.

This module does not automatically request replay and is not integrated with `replay_slot`. It is not a UCIe-defined timer or protocol controller. Timeout policy, ACK interpretation, retry exhaustion, and link reset/retrain behavior remain unspecified.
