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

	typedef enum logic[7:0]
	{
		//4:0	txpostcursor
		//12:8	txprecursor
		//19:16	txdiffctrl
		REG_LANE0_DRIVER	= 'h00,
		REG_LANE0_RATE		= 'h04,
		REG_LANE0_PATTERN	= 'h08,
		//0c reserved

		REG_LANE1_DRIVER	= 'h10,
		REG_LANE1_RATE		= 'h14,
		REG_LANE1_PATTERN	= 'h18

	} regid_t;

	//must match GTPMode in hwinit.h
	typedef enum logic[3:0]
	{
		PATTERN_PRBS7,
		PATTERN_PRBS31,
		PATTERN_BASEX,
		PATTERN_QSGMII,
		PATTERN_2UI_CLOCK,
		PATTERN_80UI_CLOCK
	} pattern_t;

	logic		rate_update				= 0;
	logic		pattern_update			= 0;

	logic[4:0]	lane0_tx_postcursor		= 0;
	logic[4:0]	lane0_tx_precursor		= 0;
	logic[3:0]	lane0_tx_diffctrl		= 0;

	pattern_t	lane0_tx_pattern		= PATTERN_PRBS7;

	logic[2:0]	lane0_tx_rate			= 1;

	logic[4:0]	lane1_tx_postcursor		= 0;
	logic[4:0]	lane1_tx_precursor		= 0;
	logic[3:0]	lane1_tx_diffctrl		= 0;

	pattern_t	lane1_tx_pattern		= PATTERN_PRBS7;

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

					REG_LANE0_PATTERN:	apb.prdata	= lane0_tx_pattern;
					REG_LANE1_PATTERN:	apb.prdata	= lane1_tx_pattern;

					default:			apb.pslverr	= 1;
				endcase
			end

			//write
			else begin
				if( (apb.paddr != REG_LANE0_DRIVER) &&
					(apb.paddr != REG_LANE1_DRIVER) &&
					(apb.paddr != REG_LANE0_PATTERN) &&
					(apb.paddr != REG_LANE1_PATTERN) &&
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
			pattern_update		<= 0;

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

					REG_LANE0_PATTERN: begin
						lane0_tx_pattern	<= pattern_t'(apb.pwdata);
						pattern_update		<= 1;
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

					REG_LANE1_PATTERN: begin
						lane1_tx_pattern	<= pattern_t'(apb.pwdata);
						pattern_update		<= 1;
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
	// Synchronizers for pushing registers into TX clock domain

	wire[2:0]	lane0_tx_rate_sync;
	wire[2:0]	lane1_tx_rate_sync;

	pattern_t	lane0_tx_pattern_sync;
	pattern_t	lane1_tx_pattern_sync;

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

	RegisterSynchronizer #(
		.WIDTH($bits(pattern_t)),
		.INIT(PATTERN_PRBS7),
		.IN_REG(1)
	) sync_lane0_pattern(
		.clk_a(apb.pclk),
		.en_a(pattern_update),
		.ack_a(),
		.reg_a(lane0_tx_pattern),

		.clk_b(lane0_txusrclk2),
		.updated_b(),
		.reset_b(1'b0),
		.reg_b(lane0_tx_pattern_sync)
	);

	RegisterSynchronizer #(
		.WIDTH($bits(pattern_t)),
		.INIT(PATTERN_PRBS7),
		.IN_REG(1)
	) sync_lane1_pattern(
		.clk_a(apb.pclk),
		.en_a(pattern_update),
		.ack_a(),
		.reg_a(lane1_tx_pattern),

		.clk_b(lane1_txusrclk2),
		.updated_b(),
		.reset_b(1'b0),
		.reg_b(lane1_tx_pattern_sync)
	);

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// PRBS-7 generators

	wire[19:0] lane0_prbs7;
	wire[19:0] lane1_prbs7;

	PRBS7 #(
		.WIDTH(20),
		.INITIAL_SEED(1)
	) lane0_prbs7_gen (
		.clk(lane0_txusrclk2),
		.update(1'b1),
		.init(1'b0),
		.seed(7'b0),
		.dout(lane0_prbs7)
	);

	PRBS7 #(
		.WIDTH(20),
		.INITIAL_SEED(1)
	) lane1_prbs7_gen (
		.clk(lane1_txusrclk2),
		.update(1'b1),
		.init(1'b0),
		.seed(7'b0),
		.dout(lane1_prbs7)
	);

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// PRBS-31 generators

	wire[19:0] lane0_prbs31;
	wire[19:0] lane1_prbs31;

	PRBS31 #(
		.WIDTH(20),
		.INITIAL_SEED(1)
	) lane0_prbs31_gen (
		.clk(lane0_txusrclk2),
		.update(1'b1),
		.init(1'b0),
		.seed(7'b0),
		.dout(lane0_prbs31)
	);

	PRBS31 #(
		.WIDTH(20),
		.INITIAL_SEED(1)
	) lane1_prbs31_gen (
		.clk(lane1_txusrclk2),
		.update(1'b1),
		.init(1'b0),
		.seed(7'b0),
		.dout(lane1_prbs31)
	);

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Datapath muxes
	// TODO: refactor this to not be doubled up

	logic[19:0] lane0_txd 		= 0;
	logic[1:0]	lane0_tx_kchar	= 0;
	logic		lane0_is_8b10b	= 0;

	logic[19:0] lane1_txd 		= 0;
	logic[1:0]	lane1_tx_kchar	= 0;
	logic		lane1_is_8b10b	= 0;

	logic[1:0]	lane0_count		= 0;
	logic[1:0]	lane1_count		= 0;

	always_ff @(posedge lane0_txusrclk2) begin
		lane0_tx_kchar	<= 0;
		lane0_is_8b10b	<= 0;

		case(lane0_tx_pattern_sync)
			PATTERN_PRBS7:	lane0_txd	<= lane0_prbs7;
			PATTERN_PRBS31:	lane0_txd	<= lane0_prbs31;

			PATTERN_BASEX: begin
				lane0_txd				<= 16'h50bc;
				lane0_tx_kchar			<= 2'b01;
				lane0_is_8b10b			<= 1;
			end

			PATTERN_QSGMII: begin
				lane0_count				<= lane0_count + 1;
				lane0_is_8b10b			<= 1;

				case(lane0_count)
					0: begin
						lane0_txd		<= 16'h3cbc;
						lane0_tx_kchar	<= 2'b11;
					end

					1: begin
						lane0_txd		<= 16'hbcbc;
						lane0_tx_kchar	<= 2'b11;
					end

					2: begin
						lane0_txd		<= 16'h5050;
						lane0_tx_kchar	<= 2'b00;
					end

					3: begin
						lane0_txd		<= 16'h5050;
						lane0_tx_kchar	<= 2'b00;
					end

				endcase

			end	//PATTERN_QSGMII

			PATTERN_2UI_CLOCK:	lane0_txd	<= 20'h55555;

			PATTERN_80UI_CLOCK: begin
				lane0_count				<= lane0_count + 1;

				case(lane0_count)
					0:			lane0_txd <= 20'h00000;
					1:			lane0_txd <= 20'h00000;
					2:			lane0_txd <= 20'hfffff;
					3:			lane0_txd <= 20'hfffff;
				endcase
			end //PATTERN_80UI_CLOCK

			default:		lane0_txd	<= 0;
		endcase
	end

	//this should always be an exact copy of the above block with lane numbers swapped, until we refactor
	always_ff @(posedge lane1_txusrclk2) begin
		lane1_tx_kchar	<= 0;
		lane1_is_8b10b	<= 0;

		case(lane1_tx_pattern_sync)
			PATTERN_PRBS7:	lane1_txd	<= lane1_prbs7;
			PATTERN_PRBS31:	lane1_txd	<= lane1_prbs31;
			PATTERN_BASEX: begin
				lane1_txd				<= 16'h50bc;
				lane1_tx_kchar			<= 2'b01;
				lane1_is_8b10b			<= 1;
			end

			PATTERN_QSGMII: begin
				lane1_count				<= lane1_count + 1;
				lane1_is_8b10b			<= 1;

				case(lane1_count)
					0: begin
						lane1_txd		<= 16'h3cbc;
						lane1_tx_kchar	<= 2'b11;
					end

					1: begin
						lane1_txd		<= 16'hbcbc;
						lane1_tx_kchar	<= 2'b11;
					end

					2: begin
						lane1_txd		<= 16'h5050;
						lane1_tx_kchar	<= 2'b00;
					end

					3: begin
						lane1_txd		<= 16'h5050;
						lane1_tx_kchar	<= 2'b00;
					end

				endcase

			end	//PATTERN_QSGMII

			PATTERN_2UI_CLOCK:	lane1_txd	<= 20'h55555;

			PATTERN_80UI_CLOCK: begin
				lane1_count				<= lane1_count + 1;

				case(lane1_count)
					0:			lane1_txd <= 20'h00000;
					1:			lane1_txd <= 20'h00000;
					2:			lane1_txd <= 20'hfffff;
					3:			lane1_txd <= 20'hfffff;
				endcase
			end //PATTERN_80UI_CLOCK

			default:		lane1_txd	<= 0;
		endcase
	end

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// 8b10b unpacking

	logic[15:0] lane0_tx_data			= 0;
	logic[1:0]	lane0_tx_charisk		= 0;
	logic[1:0]	lane0_tx_chardispmode	= 0;
	logic[1:0]	lane0_tx_chardispval	= 0;
	logic		lane0_tx_8b10b_en		= 0;

	logic[15:0] lane1_tx_data 			= 0;
	logic[1:0]	lane1_tx_charisk		= 0;
	logic[1:0]	lane1_tx_chardispmode	= 0;
	logic[1:0]	lane1_tx_chardispval	= 0;
	logic		lane1_tx_8b10b_en		= 0;

	always_ff @(posedge lane0_txusrclk2) begin

		//Enable 8b10b mode
		lane0_tx_8b10b_en				<= lane0_is_8b10b;

		if(lane0_is_8b10b) begin
			lane0_tx_data				<= lane0_txd[15:0];
			lane0_tx_charisk			<= lane0_tx_kchar;
			lane0_tx_chardispmode		<= 2'b0;
			lane0_tx_chardispval		<= 0;
		end

		//See UG482 table 3-2
		else begin
			lane0_tx_data				<= { lane0_txd[17:10], lane0_txd[7:0] };
			lane0_tx_chardispval[0]		<= lane0_txd[8];
			lane0_tx_chardispval[1]		<= lane0_txd[18];
			lane0_tx_chardispmode[0]	<= lane0_txd[9];
			lane0_tx_chardispmode[1]	<= lane0_txd[19];
		end

	end

	always_ff @(posedge lane1_txusrclk2) begin

		//Enable 8b10b mode
		lane1_tx_8b10b_en	<= lane1_is_8b10b;

		if(lane1_is_8b10b) begin
			lane1_tx_data			<= lane1_txd[15:0];
			lane1_tx_charisk		<= lane1_tx_kchar;
			lane1_tx_chardispmode	<= 2'b0;
			lane1_tx_chardispval	<= 0;
		end

		//See UG482 table 3-2
		else begin
			lane1_tx_data				<= { lane1_txd[17:10], lane1_txd[7:0] };
			lane1_tx_chardispval[0]		<= lane1_txd[8];
			lane1_tx_chardispval[1]		<= lane1_txd[18];
			lane1_tx_chardispmode[0]	<= lane1_txd[9];
			lane1_tx_chardispmode[1]	<= lane1_txd[19];
		end

	end

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
		.gt0_tx8b10ben_in(lane0_tx_8b10b_en),
		.gt0_txdata_in(lane0_tx_data),
		.gt0_txcharisk_in(lane0_tx_charisk),
		.gt0_txchardispmode_in(lane0_tx_chardispmode),
		.gt0_txchardispval_in(lane0_tx_chardispval),

		.gt1_tx8b10ben_in(lane1_tx_8b10b_en),
		.gt1_txdata_in(lane1_tx_data),
		.gt1_txcharisk_in(lane1_tx_charisk),
		.gt1_txchardispmode_in(lane1_tx_chardispmode),
		.gt1_txchardispval_in(lane1_tx_chardispval),

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
