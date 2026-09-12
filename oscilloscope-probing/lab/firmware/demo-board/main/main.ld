MEMORY
{
	FMC_APB1(RW):	ORIGIN = 0xc0000000, LENGTH = 64K
	FMC_APB2(RW):	ORIGIN = 0xc0010000, LENGTH = 64K
	/* FMC_APB64(RW):	ORIGIN = 0xc0800000, LENGTH = 1M */
}

SECTIONS
{
	.sfr_fpga_apb1  (NOLOAD):
	{
		. = ALIGN(1024);
		KEEP (*(.fdevinfo))

		. = ALIGN(1024);
		KEEP (*(.fxadc))

		. = ALIGN(1024);
		KEEP (*(.frgbled))

		. = ALIGN(1024);
		KEEP (*(.fgpioa))

		. = ALIGN(1024);
		KEEP (*(.fqspi))

		. = ALIGN(1024);
		KEEP (*(.fsmagen))

		. = ALIGN(1024);
		KEEP (*(.fclipgen))

		. = ALIGN(1024);
		KEEP (*(.fgtpgen))

	} > FMC_APB1

	/*
	.sfr_fpga_apb2  (NOLOAD):
	{
	} > FMC_APB2
	*/

	/* 64-bit APB segment for fast data output */
	/*
	.sfr_fpga_apb64 (NOLOAD):
	{
	} > FMC_APB64
	*/
}
