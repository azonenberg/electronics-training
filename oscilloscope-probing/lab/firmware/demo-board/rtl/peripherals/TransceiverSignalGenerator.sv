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

module TransceiverSignalGenerator(
	input wire			clk_125mhz,

	input wire			gtp_refclk_p,
	input wire			gtp_refclk_n,

	output wire			gtp_tx0_p,
	output wire			gtp_tx0_n,

	output wire			gtp_tx1_p,
	output wire			gtp_tx1_n
);

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// The transceiver

	wire lane0_txusrclk;
	wire lane0_txusrclk2;

	wire lane1_txusrclk;
	wire lane1_txusrclk2;

	gtwizard_0 gtwiz(

		//Resets
		.soft_reset_tx_in(1'b0),
		.dont_reset_on_data_error_in(1'b1),
		.gt0_tx_fsm_reset_done_out(),
		.gt0_rx_fsm_reset_done_out(),
		.gt0_txresetdone_out(),
		.gt1_txresetdone_out(),
		.gt1_tx_fsm_reset_done_out(),
		.gt1_rx_fsm_reset_done_out(),
		.gt0_gttxreset_in(1'b0),
		.gt1_gttxreset_in(1'b0),

		//Not using RX
		.gt0_gtrxreset_in(1'b0),
		.gt0_rxlpmreset_in(1'b0),
		.gt1_gtrxreset_in(1'b0),
		.gt1_rxlpmreset_in(1'b0),

		//Not using eye scan
		.gt0_eyescanreset_in(1'b0),
		.gt0_eyescandataerror_out(),
		.gt0_eyescantrigger_in(1'b0),
		.gt0_dmonitorout_out(),
		.gt1_eyescanreset_in(1'b0),
		.gt1_eyescandataerror_out(),
		.gt1_eyescantrigger_in(1'b0),
		.gt1_dmonitorout_out(),

		//TODO lane 0 APB
		.gt0_drpaddr_in(9'h0),
		.gt0_drpdi_in(16'h0),
		.gt0_drpdo_out(),
		.gt0_drpen_in(1'b0),
		.gt0_drprdy_out(),
		.gt0_drpwe_in(1'b0),

		//TODO lane 1 APB
		.gt1_drpaddr_in(9'h0),
		.gt1_drpdi_in(16'h0),
		.gt1_drpdo_out(),
		.gt1_drpen_in(1'b0),
		.gt1_drprdy_out(),
		.gt1_drpwe_in(1'b0),

		//QPLL
		.q0_clk0_gtrefclk_pad_p_in(gtp_refclk_p),
		.q0_clk0_gtrefclk_pad_n_in(gtp_refclk_n),
		.gt0_pll0outclk_out(),
		.gt0_pll0outrefclk_out(),
		.gt0_pll0lock_out(),
		.gt0_pll0refclklost_out(),
		.gt0_pll1outclk_out(),
		.gt0_pll1outrefclk_out(),
		.sysclk_in(clk_125mhz),

		//Valid flags
		.gt0_data_valid_in(1'b1),
		.gt1_data_valid_in(1'b1),
		.gt0_txuserrdy_in(1'b1),
		.gt1_txuserrdy_in(1'b1),

		//Clocks
		.gt0_txusrclk_out(lane0_txusrclk),
		.gt0_txusrclk2_out(lane0_txusrclk2),
		.gt0_txoutclkfabric_out(),
		.gt0_txoutclkpcs_out(),

		.gt1_txusrclk_out(lane1_txusrclk),
		.gt1_txusrclk2_out(lane1_txusrclk2),
		.gt1_txoutclkfabric_out(),
		.gt1_txoutclkpcs_out(),

		//TX driver config, registers TODO
		.gt0_txpostcursor_in(5'b0),
		.gt0_txprecursor_in(5'b0),
		.gt0_txdiffctrl_in(4'h0),

		.gt1_txpostcursor_in(5'b0),
		.gt1_txprecursor_in(5'b0),
		.gt1_txdiffctrl_in(4'h0),

		//Transmit data
		.gt0_txdata_in(16'h55aa),
		.gt1_txdata_in(16'h55aa),

		//Sub-rate control
		.gt0_txrate_in(3'b0),
		.gt0_txratedone_out(),
		.gt1_txrate_in(3'b0),
		.gt1_txratedone_out(),

		//The actual differential pairs
		.gt0_gtptxp_out(gtp_tx0_p),
		.gt0_gtptxn_out(gtp_tx0_n),
		.gt1_gtptxp_out(gtp_tx1_p),
		.gt1_gtptxn_out(gtp_tx1_n)
	);

endmodule
