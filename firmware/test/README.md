# Tests

Tests of the BIOS routines that run in sim65, the simulator that comes with cc65. 

## Run

```sh
./run_tests.sh              # build the BIOS and run every *_test.s
./run_tests.sh via_ports    # run only via_ports_test.s
TEST_ROM=../out/simple6502.bin ./run_tests.sh   # test a ROM image you already have
```

It prints `PASS name`, or `FAIL name: check 32, line 97: ...` with the line of the check that
failed. The exit code is 0 only if everything passed.

## How it works

- `run_tests.sh` builds `BIOS.s` in a temporary folder (nothing in `out/` changes), assembles the
  test, and runs it in sim65 with the ROM at $8000 and the test at $0300.
- A test calls the BIOS through the jump table, like a real program does.
- In sim65 all memory is RAM. A test can set up the BIOS state it needs (`BIOS_MACHINE_CONFIG`
  for example) and read back what a routine wrote to a hardware register: a write to the VIA
  at $7F21 can be read at $7F21.

## What it cannot test

sim65 has no peripherals, so it tests a routine's logic and the register addresses it uses. It
cannot test how the VIA or the ACIA behave, interrupts, timing (the TOCKS tick) or the serial
side of WozMon. Use the emulator or the board for those.

## Writing a test

Make `name_test.s`: include `bios_jumptable.inc` and `test.inc`, put the code in the
`USR_PROGRAM` segment and end with `PASS`. `test.inc` has the helpers (`SETREGS`, `CC`, `CS`,
`KEPT`, `AKEPT`, `MEM`, `FAIL`, `PASS`). Give every check a different number from 1 to 125, the
runner refuses a test that repeats one. `via_ports_test.s` is an example.

To see that a new test can fail, patch a byte in a copy of the ROM and run the test with
`TEST_ROM`.

## Requirements

cc65 (`ca65`, `ld65` and `sim65`).
