#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
if ! command -v iverilog >/dev/null || ! command -v vvp >/dev/null; then
  echo "BLOCKED: Icarus Verilog missing; no RTL test executed." >&2
  exit 2
fi
mkdir -p build
iverilog -g2012 -Wall -s tb_experimental_stopwait -o build/tb_experimental_stopwait \
  rtl/crc16_ccitt.sv rtl/experimental_stopwait_tx.sv \
  rtl/experimental_stopwait_rx.sv tb/experimental_fault_link.sv \
  tb/tb_experimental_stopwait.sv
vvp build/tb_experimental_stopwait
