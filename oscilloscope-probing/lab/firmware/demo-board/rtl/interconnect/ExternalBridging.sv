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
	@brief External bus interface bridge logic
 */
module ExternalBridging(

	input wire			clk_100mhz,

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

	//Debug APB UART
	input wire			uart_cts_n,
	input wire			uart_rx,
	output wire			uart_rts_n,
	output wire			uart_tx,

	//Main system APB
	APB.requester 		apb_fmc,

	//Debug APB
	APB.requester 		apb_debug
);

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// FMC APB

	APB #(.DATA_WIDTH(64), .ADDR_WIDTH(24), .USER_WIDTH(0)) apb_x64_unused();

	FMC_APBBridge #(
		.CLOCK_PERIOD(8),			//125 MHz
		.VCO_MULT(10),				//1.25 GHz VCO
		.CAPTURE_CLOCK_PHASE(-30),
		.LAUNCH_CLOCK_PHASE(-60),
		.BASE_X64(32'hff000000)
	) fmcbridge(

		.apb_x32(apb_fmc),
		.apb_x64(apb_x64_unused),

		.clk_mgmt(clk_100mhz),

		.fmc_clk(fmc_clk),
		.fmc_nwait(fmc_nwait),
		.fmc_noe(fmc_noe),
		.fmc_ad(fmc_ad),
		.fmc_nwe(fmc_nwe),
		.fmc_nbl(fmc_nbl),
		.fmc_nl_nadv(fmc_nl_nadv),
		.fmc_a_hi({3'b0, fmc_a_hi[6:0]}),
		.fmc_cs_n(fmc_ne1)
		//TODO: support multiple ranges with multiple CSes
	);

	//Tie off the x64 APB so we don't hang if we try to access that range, just return bus error
	assign apb_x64_unused.pready = apb_x64_unused.penable;
	assign apb_x64_unused.pslverr = 1;

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Debug APB

	UART_APBBridge #(
		.DEBUG_ROM_ADDR(32'h4000_0000)
	) uartbridge (
		.clk(clk_100mhz),
		.rst_n(1'b1),
		.baud_div(16'd100),		//1 Mbaud (3 seems to drop bytes without flow control)
								//TODO: support flow control?

		.uart_rx(uart_rx),
		.uart_tx(uart_tx),

		.apb(apb_debug));

endmodule
