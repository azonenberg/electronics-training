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
	@brief Top level file
 */
module top(

	//System clock input
	input wire			clk_25mhz,

	//FMC pins to MCU for APB interface
	input wire			fmc_clk,
	output wire			fmc_nwait,
	input wire			fmc_noe,
	inout wire[15:0]	fmc_ad,
	input wire			fmc_nwe,
	input wire[1:0]		fmc_nbl,
	input wire			fmc_nl_nadv,
	input wire[6:0]		fmc_a_hi,
	input wire			fmc_ne4,
	input wire			fmc_ne3,
	input wire			fmc_ne2,
	input wire			fmc_ne1,

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

	//Debug APB UART
	input wire			uart_cts_n,
	input wire			uart_rx,
	output wire			uart_rts_n,
	output wire			uart_tx,

	//Debug LEDs
	output wire[3:0]	led,

	//RGB LED controller
	output wire			led_ctrl,

	//GTP TX
	input wire			gtp_ref_p,
	input wire			gtp_ref_n/*,

	output wire			gtp_tx0_p,
	output wire			gtp_tx0_n,

	output wire			gtp_tx1_p,
	output wire			gtp_tx1_n*/
);

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Top level clocking

	wire	gtp_refclk;
	wire	clk_50mhz;
	wire	clk_100mhz;

	ClockGeneration clkgen(
		.clk_25mhz(clk_25mhz),

		.gtp_ref_p(gtp_ref_p),
		.gtp_ref_n(gtp_ref_n),

		.gtp_refclk(gtp_refclk),

		.clk_50mhz(clk_50mhz),
		.clk_100mhz(clk_100mhz)
	);

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// APB interconnect

	//Two independent buses with no connection; main bus is only bridged to MCU and debug bus only to UART
	//FMC APB is externally mapped at 0xc000_0000 and internally 0000_0000
	//Debug APB is not externally memory mapped, and internally 4000_0000
	APB #(.DATA_WIDTH(32), .ADDR_WIDTH(24), .USER_WIDTH(0)) apb_fmc();
	APB #(.ADDR_WIDTH(32), .DATA_WIDTH(32), .USER_WIDTH(0)) apb_debug();

	ExternalBridging extbridge(
		.clk_100mhz(clk_100mhz),

		.fmc_clk(fmc_clk),
		.fmc_nwait(fmc_nwait),
		.fmc_noe(fmc_noe),
		.fmc_ad(fmc_ad),
		.fmc_nwe(fmc_nwe),
		.fmc_nbl(fmc_nbl),
		.fmc_nl_nadv(fmc_nl_nadv),
		.fmc_a_hi(fmc_a_hi),
		.fmc_ne4(fmc_ne4),
		.fmc_ne3(fmc_ne3),
		.fmc_ne2(fmc_ne2),
		.fmc_ne1(fmc_ne1),

		.uart_cts_n(uart_cts_n),
		.uart_rx(uart_rx),
		.uart_rts_n(uart_rts_n),
		.uart_tx(uart_tx),

		.apb_fmc(apb_fmc),
		.apb_debug(apb_debug)
	);

	//APB1 (0xc000_0000, 1 kB per peripheral)
	APB #(.DATA_WIDTH(32), .ADDR_WIDTH(16), .USER_WIDTH(0)) apb1();

	//APB2 (0xc001_0000, 4 kB per peripheral)
	APB #(.DATA_WIDTH(32), .ADDR_WIDTH(16), .USER_WIDTH(0)) apb2();

	APBInterconnect busmatrix(
		.apb_fmc(apb_fmc),
		.apb_debug(apb_debug),

		.apb1(apb1),
		.apb2(apb2)
	);

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// APB peripherals

	PeripheralTop peripherals(
		.clk_50mhz(clk_50mhz),

		.apb1(apb1),
		.apb2(apb2),

		.flash_dq(flash_dq),
		.flash_cs_n(flash_cs_n),

		.pam3_tx_p(pam3_tx_p),
		.pam3_tx_n(pam3_tx_n),

		.coax_out(coax_out),
		.clip_out(clip_out),

		.pmod_io(pmod_io),

		.led(led),

		.led_ctrl(led_ctrl)
	);

endmodule
