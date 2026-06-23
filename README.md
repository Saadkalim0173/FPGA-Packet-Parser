# FPGA-Packet-Parser
Custom RTL based FPGA Packet Parser with custom test-benches and UVM library testing. 

## Overview

This project implements a synthesizable SystemVerilog packet parser and a UVM-based verification environment for validating packet-processing behavior under normal and malformed traffic conditions.

The design supports variable-length packets, CRC validation, metadata extraction, valid/ready flow control, and protocol error detection. The verification framework uses constrained-random stimulus, self-checking scoreboards, SystemVerilog Assertions, and functional coverage collection.

## Project Highlights

* Designed a synthesizable SystemVerilog packet parser for variable-length packets from 64B to 1KB.
* Implemented packet header decoding, payload-length validation, CRC16 checking, and metadata extraction.
* Built a UVM-compliant constrained-random verification environment.
* Developed custom UVM Agents, Drivers, Monitors, Sequencers, Scoreboards, and Sequences.
* Implemented 25+ SystemVerilog Assertions for handshaking, reset behavior, protocol compliance, and error handling.
* Achieved 89.3% functional coverage across packet types, malformed-packet scenarios, CRC-error paths, and boundary-condition tests.
* Identified remaining coverage gaps in payload-length distribution and valid/ready backpressure scenarios.
* Ran 500+ randomized regression simulations in QuestaSim.

## Packet Format

| Field           |    Size | Description                   |
| --------------- | ------: | ----------------------------- |
| SOF             |  1 byte | Start-of-frame marker, `0xAB` |
| Packet Type     |  1 byte | DATA, CTRL, or ACK packet     |
| Payload Length  | 2 bytes | Variable payload length       |
| Source ID       | 4 bytes | Source identifier             |
| Destination ID  | 4 bytes | Destination identifier        |
| Sequence Number | 2 bytes | Packet sequence number        |
| CRC16           | 2 bytes | CRC over header bytes 0–13    |

## Tools Used

* SystemVerilog
* UVM
* QuestaSim / ModelSim
* Quartus Prime
* Git / GitHub

## Repository Structure

```text
```text
FPGA-Packet-Parser/
├── README.md
├── rtl/
│   ├── packet_pkg.sv
│   ├── crc16.sv
│   ├── packet_parser.sv
│   └── packet_parser_sva.sv
├── tb/
│   ├── parser_interface.sv
│   ├── pkt_seq_item.sv
│   ├── pkt_driver.sv
│   ├── pkt_monitor.sv
│   ├── pkt_scoreboard.sv
│   ├── pkt_agent.sv
│   ├── pkt_env.sv
│   ├── pkt_sequences.sv
│   ├── pkt_coverage.sv
│   ├── pkt_test.sv
│   └── tb_top.sv
├── sim/
│   └── run_sim.do
├── docs/
│   └── regression_results.txt
└── .gitignore
```

```

## RTL Design

The RTL packet parser receives packet data as an 8-bit byte stream using a valid/ready handshake. The parser detects the start-of-frame byte, captures the packet header, validates the payload length, computes and compares CRC16, and outputs decoded metadata.

Major RTL blocks include:

* Header shift register
* Packet parsing FSM
* Payload byte counter
* CRC16 calculation logic
* Metadata extraction logic
* Valid/ready output control
* Error detection for malformed packets

## Verification Environment

The UVM testbench generates both valid and invalid packet traffic. It includes constrained-random sequences for normal packets, CRC-error injection, invalid SOF values, malformed payload lengths, and boundary-case packet sizes.

The verification environment includes:

* Sequence Item: models packet fields and error-injection controls
* Sequences: generate normal, malformed, CRC-error, and boundary packets
* Driver: converts packet transactions into byte-level DUT stimulus
* Monitor: observes DUT outputs and converts signal activity into transactions
* Scoreboard: checks DUT outputs against expected protocol behavior
* Coverage Collector: tracks functional coverage across packet types, payload ranges, and error scenarios
* SVA Module: checks protocol rules and handshake correctness

## Functional Coverage

Final functional coverage achieved: **89.3%**

Covered scenarios include:

* DATA, CTRL, and ACK packet types
* Valid packets
* CRC-error packets
* Malformed-packet paths
* Boundary payload lengths
* Protocol-state transitions
* Valid/ready handshake behavior

Remaining coverage gaps were mainly related to:

* Payload-length range distribution
* Backpressure and valid/ready transactional handshake combinations

## Running the Simulation

Open QuestaSim and navigate to the simulation directory:

```tcl
cd path/to/packet-parser-uvm/sim
do run_sim.do
```

The script compiles the RTL, UVM testbench, assertions, and runs the full UVM regression test.

Expected simulation output includes:

```text
UVM_INFO: Running test pkt_full_test
UVM_INFO: PASS packets detected by scoreboard
UVM_INFO: CRC-error packets detected correctly
UVM_INFO: Functional Coverage: 89.3%
UVM_INFO: TEST PASSED
```
## Verification Results

- Synopsys VCS simulation completed successfully
- UVM 1.2 verification environment
- Custom driver, monitor, scoreboard, agent, environment
- CRC error injection verified
- Malformed packet testing verified
- Functional coverage: 89.3%
- 25+ SystemVerilog Assertions

## Quartus Synthesis

To check RTL synthesizability in Quartus:

1. Open Quartus Prime.
2. Create a new project.
3. Add only the RTL files from the `rtl/` directory.
4. Set `packet_parser` as the top-level module.
5. Run Analysis & Synthesis.
6. Confirm successful synthesis with no critical RTL errors.

Do not add UVM testbench files to Quartus because they are simulation-only.

## Key Learning Outcomes

Through this project, I gained hands-on experience with RTL design, UVM verification, constrained-random testing, functional coverage, SVA assertions, waveform debugging, and regression-based verification methodology.

The most important learning outcome was understanding that design verification is not only about writing test stimulus, but also about building reusable infrastructure that automatically detects bugs, measures coverage, and validates protocol correctness.
