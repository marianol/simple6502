# simple6502

My own take on a simple 6502 single board computer, inspired on Garth Wilson's excellent 6502 Primer, Daryl Rictor, Ben Eater, and my own beautiful C=64 and all the classic 8-bit computers of the late 70s early 80s.

This project exists because of scope creep on my YAsixfive02 project, which is in its 10000 iteration.

## Design 

The goal is to build a simple 6502 SBC with RAM, ROM, IO decoding and a serial interface. An expansion  bus will carry all the address, data and supporting lines to allow adding IO and other hardware expansions. 
Target clock spped will be 2 Mhz. The PCB will be kept at 100x100mm to reduce cost.

## Memory Map

Momory Decocing is done using gates for RAM, ROM and IO. IO_CS line is sent to a 3-8 decoder to get 8 individual IO select lines.
IO line  $\overline{IO\textunderscore08}$ is used for the onboard ACIA for serial communication.
IO lines  $\overline{IO\textunderscore01}$ and $\overline{IO\textunderscore02}$ are sent to pin 27 of Slot 1 and 2 respectively. This allows cards that use this pin to get mapped to the memory based on the Slot they are inserted.

### Address Space

- 0x0000 - 0x7EFF : RAM 32K - 256 bytes (31.75k)
- 0x7F00 - 0x7F0F : IO_1 > SLOT 1
- 0x7F10 - 0x7F1F : IO_2 > SLOT 2
- 0x7F20 - 0x7F2F : IO_3
- 0x7F30 - 0x7F3F : IO_4
- 0x7F40 - 0x7F4F : IO_5
- 0x7F50 - 0x7F5F : IO_6
- 0x7F60 - 0x7F6F : IO_7
- 0x7F70 - 0x7F7F : IO_8 > ACIA
- 0x7F80 - 0x7FFF : Not Decoded
- 0x8000 - 0xFFFF : ROM (32K)

## Card Connector Design

The card connector is based on the EDAC 395 series. I decided on the 395-50-520-201 which I had from a previous Apple ][ repair.
Exposed in the connector are:

- Address lines A0..A15
- Data lines D0..D7
- Clock $\phi$ 2
- $\overline{IO{\textunderscore}CS}$, $\overline{RAM{\textunderscore}CS}$ , and $\overline{ROM{\textunderscore}CS}$ chip select lines
- $\overline{RD}$ and $\overline{WR}$ 
- $\overline{RESET}$
- Pin 27 is the slot IO select line. For Slot 1 is $\overline{IO\textunderscore01}$ mapping it to 0x7F00, and for Slot 2 is $\overline{IO\textunderscore02}$ mapping it to 0x7F10.
- IO chip select lines $\overline{IO\textunderscore03}$ .. $\overline{IO\textunderscore07}$.
- $\overline{IRQ}$ and $\overline{NMI}$
- VCC and GND, this are set so if you insert a card backwards you will not short them.
- Pins 21, 24, 33, and 34 are only connected between the 2 slots and have no connection to the mainboard 

## Licence

Licenced under CERN Open Hardware licence CERN-OHL-S v2, see CERN-OHL-S-v2.txt

(c) 2023-2024 Mariano Luna. All rights reserved
