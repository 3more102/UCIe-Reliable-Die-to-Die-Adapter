#!/usr/bin/env bash
# Portable directed RTL regression. Requires Icarus Verilog (iverilog and vvp).
set -euo pipefail
cd "$(dirname "$0")/.."
command -v iverilog >/dev/null || { echo "ERROR: iverilog not found" >&2; exit 127; }
command -v vvp >/dev/null || { echo "ERROR: vvp not found" >&2; exit 127; }
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
run() {
    local top="$1"
    shift
    echo "RUN $top"
    iverilog -g2012 -Wall -s "$top" -o "$tmp/$top" "$@"
    vvp "$tmp/$top"
}
run tb_elastic_buffer rtl/elastic_buffer.sv tb/tb_elastic_buffer.sv
run tb_credit_tx rtl/credit_tx.sv tb/tb_credit_tx.sv
run tb_credit_tx_edges rtl/credit_tx.sv tb/tb_credit_tx_edges.sv
run tb_link_manager rtl/link_manager.sv tb/tb_link_manager.sv
echo "PASS: all four directed RTL tests"
