#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
if ! command -v yosys >/dev/null; then
  echo "BLOCKED: Yosys missing; no generic synthesis statistics were measured" >&2
  exit 2
fi
mkdir -p build/generic_storage
for depth in 4 8 16 32 64; do
  echo "DEPTH=$depth generic synthesis (not technology-mapped area)"
  yosys -Q -p "read_verilog -sv rtl/generic_replay_store.sv; hierarchy -check -top generic_replay_store -chparam DATA_WIDTH 32 -chparam DEPTH $depth; proc; opt; memory; opt; stat" > "build/generic_storage/depth_${depth}.log"
  tail -35 "build/generic_storage/depth_${depth}.log"
done
