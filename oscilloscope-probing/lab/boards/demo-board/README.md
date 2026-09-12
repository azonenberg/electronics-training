# Demo board

## info

* ebay xc7a35t-2fgg484i
* stm32h750 running control plane
* 4x LVCMOS33 outputs for low speed stuff, wired direct from FPGA to SMAs
* A few GTPs to SMAs
* ltc3374a based power, usb-c, f234
* Some fast LVCMOS18 or similar outputs
* needs 32 mbit or larger spi flash, load more fw for stm32 from same flash if needed??

stackup: 8 layers SGS PG SGS JLC081611-2116?? going down to 6 probably wont save much

## BUGS BUGS BUGS in first board revision

* FT234 is 0.45mm pitch, footprint is 0.5. it should still solder, barely (150um max pin position error, 250um lands w/ 250um gaps)
* No pulldowns on rail enables, so they all turn on without sequencing until the supervisor is flashed and out of reset
* Not really a bug, but should have put DC blocks on PAM3 outputs so we don't need them scope side
