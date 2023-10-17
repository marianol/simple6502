# simple6502

My own take on a simple 6502 single board computer, inspired on Garth Wilson's excellent 6502 Primer, Daryl Rictor, Ben Eater, and my own beautiful C=64 and all the classic 8-bit computers of the late 70s early 80s.

This project exists because of scope creep on my YAsixfive02 project, which is in its 10000 iteration.

## Design 

The goal is to build a simple 6502 SBC with RAM, ROM, IO decoding and a debug IO port with LEDs.An espansion bus will carry all the address, data and supporting lines to allow adding IO and other hardware expansions. 
The design will be centered around a 6502 BUS that uses Apple ][ edge connectors (EDAC 395-050-520-201). The motherboard will have the basic power, reset and a simple debug IO port made of a 74HC273 octal flip-flop driving LEDs. 
Target clock spped will be 2 Mhz. 
All the PCBs will be kept at 100x100mm to reduce cost.

## Memory Map

Momory Decocing is done using gates for RAM, ROM and IO. IO_CS line is sent to a 3-8 decoder to get 8 individual IO select lines.

### Address Space

- 0x0000 - 0x7EFF : RAM 32K - 256 bytes
- 0x7F00 - 0x7FFF : I/O 256 bytes to decode
- 0x8000 - 0xFFFF : ROM 32K

## Card Connector Design

The card connector is based on the EDAC 395 series. I decided on the 395-50-520-201 which I had from a previous Apple ][ repair.
Exposed in the connector are:

- Address lines A0..A15
- Data lines D0..D7
- $\phi$ 2 Clock
- RAM and ROM chip select lines
- $\overline{RD}$ and $\overline{WR}$ 
- $\overline{RESET}$
- IO chip select lines $\overline{IO\textunderscore01}$ .. $\overline{IO\textunderscore07}$, $\overline{IO\textunderscore08}$ is used for the board debugger
- $\overline{IRQ}$ and $\overline{NMI}$
- VCC and GND, this are set so if you insert a card backwards you will not invert them



