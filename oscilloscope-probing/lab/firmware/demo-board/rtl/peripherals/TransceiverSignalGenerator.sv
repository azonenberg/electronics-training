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
	APB.completer		apb,

	input wire			clk_125mhz,

	input wire			gtp_refclk_p,
	input wire			gtp_refclk_n,

	output wire			gtp_tx0_p,
	output wire			gtp_tx0_n,

	output wire			gtp_tx1_p,
	output wire			gtp_tx1_n
);
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Sanity check bus configuration

	if(apb.DATA_WIDTH != 32)
		apb_bus_width_is_invalid();

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Tie off unused APB signals

	assign apb.pruser = 0;
	assign apb.pbuser = 0;

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Register IDs

	typedef enum logic[3:0]
	{
		//4:0	txpostcursor
		//12:8	txprecursor
		//19:16	txdiffctrl
		REG_LANE0_DRIVER	= 'h00,
		REG_LANE0_RATE		= 'h04,
		REG_LANE1_DRIVER	= 'h08,
		REG_LANE1_RATE		= 'h0c

		//TODO: pattern control
	} regid_t;

	logic[4:0]	lane0_tx_postcursor		= 0;
	logic[4:0]	lane0_tx_precursor		= 0;
	logic[3:0]	lane0_tx_diffctrl		= 0;

	logic		rate_update				= 0;
	logic[2:0]	lane0_tx_rate			= 1;

	logic[4:0]	lane1_tx_postcursor		= 0;
	logic[4:0]	lane1_tx_precursor		= 0;
	logic[3:0]	lane1_tx_diffctrl		= 0;

	logic[2:0]	lane1_tx_rate			= 1;

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Register logic

	//Combinatorial readback
	always_comb begin

		apb.pready	= apb.psel && apb.penable;
		apb.prdata	= 0;
		apb.pslverr	= 0;

		if(apb.pready) begin

			//read
			if(!apb.pwrite) begin
				case(apb.paddr)
					REG_LANE0_DRIVER:	apb.prdata	= { 12'h0, lane0_tx_diffctrl, 3'h0, lane0_tx_precursor, 3'h0, lane0_tx_postcursor };
					REG_LANE1_DRIVER:	apb.prdata	= { 12'h0, lane1_tx_diffctrl, 3'h0, lane1_tx_precursor, 3'h0, lane1_tx_postcursor };
					REG_LANE0_RATE:		apb.prdata	= { 29'h0, lane0_tx_rate };
					REG_LANE1_RATE:		apb.prdata	= { 29'h0, lane1_tx_rate };
					default:			apb.pslverr	= 1;
				endcase
			end

			//write
			else begin
				if( (apb.paddr != REG_LANE0_DRIVER) &&
					(apb.paddr != REG_LANE1_DRIVER) &&
					(apb.paddr != REG_LANE0_RATE) &&
					(apb.paddr != REG_LANE1_RATE)
					) begin

					apb.pslverr	 = 1;

				end
			end

		end
	end

	always_ff @(posedge apb.pclk or negedge apb.preset_n) begin

		//Reset
		if(!apb.preset_n) begin
			lane0_tx_postcursor	<= 0;
			lane0_tx_precursor	<= 0;
			lane0_tx_diffctrl	<= 0;
			lane1_tx_postcursor	<= 0;
			lane1_tx_precursor	<= 0;
			lane1_tx_diffctrl	<= 0;

			lane0_tx_rate		<= 1;
			lane1_tx_rate		<= 1;

			rate_update			<= 0;
		end

		//Normal path
		else begin

			rate_update			<= 0;

			if(apb.pready && apb.pwrite) begin

				case(apb.paddr)

					REG_LANE0_DRIVER: begin
						lane0_tx_postcursor	<= apb.pwdata[4:0];
						lane0_tx_precursor	<= apb.pwdata[12:8];
						lane0_tx_diffctrl	<= apb.pwdata[19:16];
					end

					REG_LANE0_RATE: begin
						lane0_tx_rate		<= apb.pwdata[2:0];
						rate_update			<= 1;
					end

					REG_LANE1_DRIVER: begin
						lane1_tx_postcursor	<= apb.pwdata[4:0];
						lane1_tx_precursor	<= apb.pwdata[12:8];
						lane1_tx_diffctrl	<= apb.pwdata[19:16];
					end

					REG_LANE1_RATE: begin
						lane1_tx_rate		<= apb.pwdata[2:0];
						rate_update			<= 1;
					end

					default: begin
					end
				endcase

			end

		end

	end

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Clocks

	wire lane0_txusrclk;
	wire lane0_txusrclk2;

	wire lane1_txusrclk;
	wire lane1_txusrclk2;

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Synchronizers for rate switching

	wire[2:0]	lane0_tx_rate_sync;
	wire[2:0]	lane1_tx_rate_sync;

	RegisterSynchronizer #(
		.WIDTH(3),
		.INIT(1),
		.IN_REG(1)
	) sync_lane0_rate(
		.clk_a(apb.pclk),
		.en_a(rate_update),
		.ack_a(),
		.reg_a(lane0_tx_rate),

		.clk_b(lane0_txusrclk2),
		.updated_b(),
		.reset_b(1'b0),
		.reg_b(lane0_tx_rate_sync)
	);

	RegisterSynchronizer #(
		.WIDTH(3),
		.INIT(1),
		.IN_REG(1)
	) sync_lane1_rate(
		.clk_a(apb.pclk),
		.en_a(rate_update),
		.ack_a(),
		.reg_a(lane1_tx_rate),

		.clk_b(lane1_txusrclk2),
		.updated_b(),
		.reset_b(1'b0),
		.reg_b(lane1_tx_rate_sync)
	);

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// PRBS generators

	wire[15:0] lane0_prbs7;
	wire[15:0] lane1_prbs7;

	PRBS7 #(
		.WIDTH(16),
		.INITIAL_SEED(1)
	) lane0_prbs7_gen (
		.clk(lane0_txusrclk2),
		.update(1'b1),
		.init(1'b0),
		.seed(7'b0),
		.dout(lane0_prbs7)
	);

	PRBS7 #(
		.WIDTH(16),
		.INITIAL_SEED(1)
	) lane1_prbs7_gen (
		.clk(lane1_txusrclk2),
		.update(1'b1),
		.init(1'b0),
		.seed(7'b0),
		.dout(lane1_prbs7)
	);

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// The transceiver

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

		//TX driver config, registers
		.gt0_txpostcursor_in(lane0_tx_postcursor),
		.gt0_txprecursor_in(lane0_tx_precursor),
		.gt0_txdiffctrl_in(lane0_tx_diffctrl),

		.gt1_txpostcursor_in(lane1_tx_postcursor),
		.gt1_txprecursor_in(lane1_tx_precursor),
		.gt1_txdiffctrl_in(lane1_tx_diffctrl),

		//Transmit data
		.gt0_txdata_in(lane0_prbs7),
		.gt1_txdata_in(lane1_prbs7),

		//Sub-rate control
		.gt0_txrate_in(lane0_tx_rate_sync),
		.gt0_txratedone_out(),
		.gt1_txrate_in(lane1_tx_rate_sync),
		.gt1_txratedone_out(),

		//The actual differential pairs
		.gt0_gtptxp_out(gtp_tx0_p),
		.gt0_gtptxn_out(gtp_tx0_n),
		.gt1_gtptxp_out(gtp_tx1_p),
		.gt1_gtptxn_out(gtp_tx1_n)
	);

endmodule
