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
	@brief Clock synthesis PLLs
 */
module ClockGeneration(

	//Main system clock input
	input wire		clk_25mhz,

	//SERDES reference clocks
	input wire		gtp_ref_p,
	input wire		gtp_ref_n,

	//Clocks out to system
	output wire		gtp_refclk,
	output wire		clk_100mhz
	);

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Main system PLL

	wire	clk_fb;

	wire	pll_lock;

	wire	clk_100mhz_raw;

	MMCME2_BASE #(
		.BANDWIDTH("OPTIMIZED"),

		.CLKOUT0_DIVIDE_F(10),		//1 GHz VCO / 10 = 100 MHz PLL out
		.CLKOUT1_DIVIDE(128),
		.CLKOUT2_DIVIDE(128),
		.CLKOUT3_DIVIDE(128),
		.CLKOUT4_DIVIDE(128),
		.CLKOUT5_DIVIDE(128),
		.CLKOUT6_DIVIDE(128),

		.CLKOUT0_PHASE(0.0),
		.CLKOUT1_PHASE(0.0),
		.CLKOUT2_PHASE(0.0),
		.CLKOUT3_PHASE(0.0),
		.CLKOUT4_PHASE(0.0),
		.CLKOUT5_PHASE(0.0),
		.CLKOUT6_PHASE(0.0),

		.CLKOUT0_DUTY_CYCLE(0.50),
		.CLKOUT1_DUTY_CYCLE(0.50),
		.CLKOUT2_DUTY_CYCLE(0.50),
		.CLKOUT3_DUTY_CYCLE(0.50),
		.CLKOUT4_DUTY_CYCLE(0.50),
		.CLKOUT5_DUTY_CYCLE(0.50),
		.CLKOUT6_DUTY_CYCLE(0.50),

		.CLKFBOUT_MULT_F(40),		//1 GHz VCO
		.DIVCLK_DIVIDE(1),			//no PFD divider
		.CLKFBOUT_PHASE(0.0),		//no phase shift
		.CLKIN1_PERIOD(40.0),		//40 ns = 25 MHz

		.STARTUP_WAIT("FALSE"),
		.CLKOUT4_CASCADE("FALSE")

	) mmcm_main (
		.CLKIN1(clk_25mhz),
		.CLKFBIN(clk_fb),
		.RST(1'b0),
		.PWRDWN(1'b0),

		.CLKOUT0(clk_100mhz_raw),
		.CLKOUT0B(),
		.CLKOUT1(),
		.CLKOUT1B(),
		.CLKOUT2(),
		.CLKOUT2B(),
		.CLKOUT3(),
		.CLKOUT3B(),
		.CLKOUT4(),
		.CLKOUT5(),
		.CLKOUT6(),

		.CLKFBOUT(clk_fb),
		.CLKFBOUTB(),

		.LOCKED(pll_lock)
	);

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Clock buffers

	BUFGCE bufg_clk_100mhz(
		.I(clk_100mhz_raw),
		.O(clk_100mhz),
		.CE(pll_lock));

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Transceiver input refclk buffer

	IBUFDS_GTE2 refclk_ibuf(
		.I(gtp_ref_p),
		.IB(gtp_ref_n),
		.CEB(1'b0),
		.O(gtp_refclk),
		.ODIV2()
	);

endmodule
