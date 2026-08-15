`timescale 1ns/1ps
`default_nettype none
/***********************************************************************************************************************
*                                                                                                                      *
* electronics-training                                                                                                 *
*                                                                                                                      *
* Copyright (c) 2026 Andrew D. Zonenberg and contributors                                                              *
* All rights reserved.                                                                                                 *
*                                                                                                                      *
* Redistribution and use in source and binary forms, with or without modification, are permitted provided that the     *
* following conditions are met:                                                                                        *
*                                                                                                                      *
*    * Redistributions of source code must retain the above copyright notice, this list of conditions, and the         *
*      following disclaimer.                                                                                           *
*                                                                                                                      *
*    * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the       *
*      following disclaimer in the documentation and/or other materials provided with the distribution.                *
*                                                                                                                      *
*    * Neither the name of the author nor the names of any contributors may be used to endorse or promote products     *
*      derived from this software without specific prior written permission.                                           *
*                                                                                                                      *
* THIS SOFTWARE IS PROVIDED BY THE AUTHORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED   *
* TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL *
* THE AUTHORS BE HELD LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES        *
* (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR       *
* BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT *
* (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE       *
* POSSIBILITY OF SUCH DAMAGE.                                                                                          *
*                                                                                                                      *
***********************************************************************************************************************/

/**
	@brief Parent module for all of the APB peripherals doing fun things
 */

module PeripheralTop(
	input wire			clk_50mhz,

	//APB1 (0xc000_0000, 1 kB per peripheral)
	APB.completer		apb1,

	//APB2 (0xc001_0000, 4 kB per peripheral)
	APB.completer		apb2,

	//QSPI flash lines
	inout wire[3:0]		flash_dq,
	output wire			flash_cs_n,
	//flash SCK is CCLK pin from STARTUPE2

	//Bitbanged PAM3 / MLT3 generator
	output wire			pam3_tx_p,
	output wire			pam3_tx_n,

	//Coax outputs
	output wire[3:0]	coax_out,

	//Probe clip IOs
	output wire[3:0]	clip_out,

	//PMOD
	inout wire[7:0]		pmod_io,

	//Debug LEDs
	output wire[3:0]	led,

	//RGB LED controller
	output wire			led_ctrl
);

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// APB1 bridging (0xc000_0000, 1 kB per peripheral)

	localparam NUM_APB1_PERIPHERALS	= 5;
	localparam APB1_BLOCK_SIZE		= 32'h400;
	localparam APB1_ADDR_WIDTH		= $clog2(APB1_BLOCK_SIZE);
	APB #(.DATA_WIDTH(32), .ADDR_WIDTH(APB1_ADDR_WIDTH), .USER_WIDTH(0)) apb1_devices[NUM_APB1_PERIPHERALS-1:0]();
	APBBridge #(
		.BASE_ADDR(32'h0000_0000),
		.BLOCK_SIZE(APB1_BLOCK_SIZE),
		.NUM_PORTS(NUM_APB1_PERIPHERALS)
	) apb1_bridge (
		.upstream(apb1),
		.downstream(apb1_devices)
	);

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// APB2 bridging (0xc001_0000, 4 kB per peripheral)

	localparam NUM_APB2_PERIPHERALS	= 2;
	localparam APB2_BLOCK_SIZE		= 32'h1000;
	localparam APB2_ADDR_WIDTH		= $clog2(APB2_BLOCK_SIZE);
	APB #(.DATA_WIDTH(32), .ADDR_WIDTH(APB2_ADDR_WIDTH), .USER_WIDTH(0)) apb2_devices[NUM_APB2_PERIPHERALS-1:0]();
	APBBridge #(
		.BASE_ADDR(32'h0000_0000),
		.BLOCK_SIZE(APB2_BLOCK_SIZE),
		.NUM_PORTS(NUM_APB2_PERIPHERALS)
	) apb2_bridge (
		.upstream(apb2),
		.downstream(apb2_devices)
	);

	//TODO: what if anything do we want to put on APB2

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Device information (c000_0000)

	APB #(.DATA_WIDTH(32), .ADDR_WIDTH(APB1_ADDR_WIDTH), .USER_WIDTH(0)) apb_devinfo();
	APBRegisterSlice #(.DOWN_REG(0), .UP_REG(1)) regslice_apb_devinfo(
		.upstream(apb1_devices[0]),
		.downstream(apb_devinfo));

	APB_DeviceInfo_7series devinfo(
		.apb(apb_devinfo),
		.clk_dna(clk_50mhz),
		.clk_icap(clk_50mhz) );

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// XADC for on-die sensors (c000_0400)

	APB #(.DATA_WIDTH(32), .ADDR_WIDTH(APB1_ADDR_WIDTH), .USER_WIDTH(0)) apb_xadc();
	APBRegisterSlice #(.DOWN_REG(1), .UP_REG(1)) regslice_apb_xadc(
		.upstream(apb1_devices[1]),
		.downstream(apb_xadc));

	APB_XADC xadc(.apb(apb_xadc));

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// RGB LED controller (c000_0800)

	APB #(.DATA_WIDTH(32), .ADDR_WIDTH(APB1_ADDR_WIDTH), .USER_WIDTH(0)) ledBus();

	APBRegisterSlice #(.UP_REG(1), .DOWN_REG(0))
		apb_regslice_led( .upstream(apb1_devices[2]), .downstream(ledBus) );

	//TODO: update timings here
	APB_SerialLED #(
		.NUM_LEDS(4),
		.SHORT_TIME(30),	//Number of PCLK cycles in a "short" pulse (300 ns)
		.LONG_TIME(90),		//Number of PCLK cycles in a "long" pulse (900 ns)
		.IFG_TIME(200),		//Number of PCLK cycles between data words
		.RESET_TIME(750)	//Number of PCLK cycles in a reset pulse (>50us, do 75 to be safe)
	)  rgbled (
		.apb(ledBus),

		.led_ctrl(led_ctrl)
	);

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// GPIO controller for LEDs and PMOD (c000_0c00)

	wire[31:0]	gpioa_out;
	wire[31:0]	gpioa_in;
	wire[31:0]	gpioa_tris;

	APB #(.DATA_WIDTH(32), .ADDR_WIDTH(APB1_ADDR_WIDTH), .USER_WIDTH(0)) apb_gpioa();
	APBRegisterSlice #(.DOWN_REG(1), .UP_REG(1)) regslice_apb_gpioa(
		.upstream(apb1_devices[3]),
		.downstream(apb_gpioa));

	APB_GPIO gpioA(
		.apb(apb_gpioa),

		.gpio_out(gpioa_out),
		.gpio_in(gpioa_in),
		.gpio_tris(gpioa_tris)
	);

	//LEDs are output only and using the low bits
	assign led				= gpioa_out[3:0];

	//tie off unused output bits
	assign gpioa_in[23:4] = 0;

	//PMOD GPIOs at 31:24
	for(genvar g=0; g<8; g++) begin : pmod
		IOBUF iobuf(
			.I(gpioa_out[24+g]),
			.O(gpioa_in[24+g]),
			.T(!gpioa_tris[24+g]),
			.IO(pmod_io[g]));
	end

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// QSPI flash controller for boot flash, not memory mapped (c000_1000)

	wire		cclk;
	wire[3:0]	flash_dq_out;
	wire[3:0]	flash_dq_in;
	wire[3:0]	flash_dq_tris;

	for(genvar g=0; g<4; g=g+1) begin : flash_iobufs
		IOBUF iobuf(
			.I(flash_dq_out[g]),
			.O(flash_dq_in[g]),
			.T(flash_dq_tris[g]),
			.IO(flash_dq[g]));
	end

	//STARTUP block
	wire	ring_clk;
	STARTUPE2 startup(
		.CLK(ring_clk),
		.GSR(1'b0),
		.GTS(1'b0),
		.KEYCLEARB(1'b1),
		.PACK(1'b0),
		.PREQ(),
		.USRCCLKO(cclk),
		.USRCCLKTS(1'b0),
		.USRDONEO(1'b1),
		.USRDONETS(1'b0),
		.CFGCLK(),
		.CFGMCLK(ring_clk),
		.EOS()
		);

	//SPI bus controller
	APB #(.DATA_WIDTH(32), .ADDR_WIDTH(APB1_ADDR_WIDTH), .USER_WIDTH(0)) apb_flash();
	APBRegisterSlice #(.DOWN_REG(1), .UP_REG(1)) regslice_apb_flash(
		.upstream(apb1_devices[4]),
		.downstream(apb_flash));

	APB_QSPIHostInterface flash(
		.apb(apb_flash),

		.qspi_sck(cclk),
		.qspi_dq_out(flash_dq_out),
		.qspi_dq_in(flash_dq_in),
		.qspi_dq_tris(flash_dq_tris),
		.qspi_cs_n(flash_cs_n)
	);

endmodule
