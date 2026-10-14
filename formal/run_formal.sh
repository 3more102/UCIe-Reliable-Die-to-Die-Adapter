#!/usr/bin/env sh
set -eu

cd "$(dirname "$0")/.."

run_proof() {
    top=$1
    rtl_files=$2
    harness=$3
    sat_options=$4
    yosys -Q -q -p "read_verilog -formal -sv $rtl_files $harness; prep -top $top; flatten; async2sync; sat $sat_options -set-init-zero -prove-asserts -verify"
    printf 'PASS formal %s (%s)\n' "$top" "$sat_options"
}

# Inductive safety/equivalence proofs over arbitrary data and control inputs.
run_proof formal_elastic_buffer \
    'rtl/elastic_buffer.sv' \
    'formal/formal_elastic_buffer.sv' \
    '-seq 4 -tempinduct -timeout 30'
run_proof formal_credit_tx \
    'rtl/credit_tx.sv' \
    'formal/formal_credit_tx.sv' \
    '-seq 4 -tempinduct -timeout 30'
run_proof formal_link_manager \
    'rtl/link_manager.sv' \
    'formal/formal_link_manager.sv' \
    '-seq 4 -tempinduct -timeout 30'
run_proof formal_generic_replay_tx \
    'rtl/crc16_ccitt.sv rtl/generic_replay_tx.sv' \
    'formal/formal_generic_replay_tx.sv' \
    '-seq 4 -tempinduct -timeout 30'

# The RX state reference needs deeper exploration; report only a bounded result.
run_proof formal_generic_crc_rx \
    'rtl/crc16_ccitt.sv rtl/generic_crc_rx.sv' \
    'formal/formal_generic_crc_rx.sv' \
    '-seq 32 -timeout 30'

# Bounded end-to-end safety: output data must match accepted source order even
# with arbitrary stalls, credit returns, CRC faults, response loss, and reset.
run_proof formal_reliable_stream_safety \
    'rtl/elastic_buffer.sv rtl/crc16_ccitt.sv rtl/credit_tx.sv rtl/link_manager.sv rtl/generic_replay_tx.sv rtl/generic_crc_rx.sv rtl/reliable_stream_model.sv' \
    'formal/formal_reliable_stream_safety.sv' \
    '-seq 16 -timeout 60'
