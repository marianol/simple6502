# SPI Communications

Most of this data comes from:

- <http://elm-chan.org/docs/mmc/mmc_e.html>
- <https://chlazza.nfshost.com/sdcardinfo.html>

## SD Commands

All data sent through the SPI bus are built around the byte - some items may have padding, but the host and card will alwasy send/recieve some multiple of 8 bits.
All command tokens are six bytes long. The card will always respond to every command token with a response token of some kind.

| Command Index | Argument | Response | Data | Abbreviation | Description
| -------- | ---------- | --- | --- | --- | ------------ | ------------------- |
| CMD0     | None(0)     | R1 | No | GO_IDLE_STATE             | Software reset.
| CMD1     | None(0)     | R1 | No | SEND_OP_COND             | Initiate initialization process.
| ACMD41 <sub>*1</sub>  | <sub>*2</sub> | R1 | No | APP_SEND_OP_COND         | For only SDC. Initiate initialization process.
| CMD8     | <sub>*3</sub> | R7 | No | SEND_IF_COND             | For only SDC V2. Check voltage range.
| CMD9     | None(0)     | R1 | Yes | SEND_CSD                 | Read CSD register.
| CMD10     | None(0)     | R1 | Yes | SEND_CID                 | Read CID register.
| CMD12     | None(0)     | R1b | No | STOP_TRANSMISSION         | Stop to read data.
| CMD16     | Block         | R1 | No | SET_BLOCKLEN             | Change R/W block size. 
|             | length[31:0] |       |       |                           |
| CMD17     | Address[31:0] | R1 | Yes | READ_SINGLE_BLOCK         | Read a block.
| CMD18     | Address[31:0] | R1 | Yes | READ_MULTIPLE_BLOCK       | Read multiple blocks.
| CMD23     | Number of     | R1 | No | SET_BLOCK_COUNT         | For only MMC. Define number of blocks to transfer
|             | blocks[15:0] |       |       |                           | with next multi-block read/write command.
| ACMD23(*1)  | Number of     | R1 | No | SET_WR_BLOCK_ERASE_COUNT | For only SDC. Define number of blocks to pre-erase
|             | blocks[22:0]  |       |       |                           | with next multi-block write command.
| CMD24     | Address[31:0] | R1 | Yes | WRITE_BLOCK             | Write a block.
| CMD25     | Address[31:0] | R1 | Yes | WRITE_MULTIPLE_BLOCK     | Write multiple blocks.
| CMD55(*1) | None(0)     | R1 | No | APP_CMD                 | Leading command of ACMD\<n> command.
| CMD58     | None(0)     | R3 | No | READ_OCR                 | Read OCR.

*1: ACMD\<n> means a command sequense of CMD55-CM\<n>.
*2: Rsv(0) [31], HCS[30], Rsv(0) [29:0]
*3: Rsv(0) [31:12], Supply Voltage(1) [11:8], Check Pattern(0xAA) [7:0]

## SPI Response

MMC and SDC
There are some command response formats, R1, R2, R3 and R7, depends on the command index. A byte of response, R1, is returned for most commands. The bit field of the R1 response is shown below, the value 0x00 means successful. When any error occured, corresponding status bit in the response will be set. The R3/R7 response (R1 + trailing 32-bit data) is for only CMD58 and CMD8.

Some commands take a time longer than NCR and it responds R1b. It is an R1 response followed by busy flag (DO is driven to low as long as internal process is in progress). The host controller should wait for end of the process until DO goes high (a 0xFF is received).

### R1

| bit 0 | bit 1 | bit 2 | bit 3 | bit 4 | bit 5 | bit 6 | bit 7 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Always Zero | Parameter Error | Address Error | Erase sequence Error | Command CRC Error | Illegal command | Erase reset | In IDLE state |

### R2

Two bytes in width. The first byte sent is identical to R1. The second byte sent is as follows:

Bit 0: Card is locked > Set when the card is locked by the user. Reset when it is unlocked.
Bit 1: Write protect erase skip | lock/unlock command failed > This status bit has two functions overloaded. It is set when the host attempts to erase a write-protected sector or makes a sequence or password errors during card lock/unlock operation.
Bit 2: Error > A general or an unknown error occurred during the operation.
Bit 3: CC error > Internal card controller error.
Bit 4: Card ECC failed > Card internal ECC was applied but failed to correct the data.
Bit 5: Write protect violation > The command tried to write a write-protected block.
Bit 6: Erase param > An invalid selection for erase, sectors or groups.
Bit 7: out of range | csd overwrite.

### R3

Five bytes in width. The first byte sent is identical to R1. The following four bytes are the contents of the OCR register.

### R7

R7 is 5 bytes long, and the first byte is identical to R1. Following that we have a command version field, a voltage accepted field, and an "echo-back" of the check pattern we sent in the command. Note that if you are using a first generation card, it will only return R1 with the illegal bit command set.

Bit 0-7:   R1 response
Bit 8-11:  Command version
Bit 12-16: Reserved bits
Bit 17-21: Voltage accepted
Bit 22-20: Check pattern

The Voltage accepted pattern is as follows:
0b00000001  Voltage 2.7v to 3.3v
0b00000010  Low Voltage
0b00000100  Reserved
0b00001000  Reserved

Check pattern is an echo of the check pattern

## SD Initialization in SPI mode

<http://elm-chan.org/docs/mmc/mmc_e.html#spiinit>

1. Put thr card in native mode ready for commands, this should be done after
power On or card insertion:

- De-select CS (i.e. make it HIGH)
- Send 10 bytes of 0xFF (i.e. keep MOSI high, toggle CLK 80 times).
  
1. Set SPI mode sending a CMD0 with CS low to reset the card. Since the CMD0 must be sent as a native command, the CRC field must have a valid value.

- Assert CS (set it LOW)
- Send CMD0, then keep reading (by toggling CLK) until a 0x01 response is received

Send a CMD55 (indicates the next byte will be application specific)
Send a CMD41. If the response is not 0 then loop from CMD55 again
Once a zero comes back, the card is ready, send a CMD16 and set block size to 512 bytes

## Block Length

Read and write operations are performed on SD cards in blocks of set lengths. Block length can be set in Standard Capacity SD cards using CMD16 (SET_BLOCKLEN). For SDHC and SDXC cards cards the block length is always set to 512 bytes.
