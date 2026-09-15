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
	@brief Just enough of the 100baseTX PMA/PCS to be plausible

	Adapted from TRAGICLASER
 */
module BaseTXSignalGenerator(

	//Synchronous clock for everything
	input wire			clk_25mhz,
	input wire			clk_125mhz,

	//MII interface (clk_25mhz domain)
    input wire			mii_tx_en,
    input wire			mii_tx_er,
    input wire[3:0]		mii_txd,

	//Raw 4b5b coded data (MLT3 is handled by PAM3SignalGenerator)
	output logic		data_out	= 0
);
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// TX MII interface

	localparam CTL_IDLE		= 0;
	localparam CTL_SSD_J	= 1;
	localparam CTL_SSD_K	= 2;
	localparam CTL_END_T 	= 3;
	localparam CTL_END_R 	= 4;
	localparam CTL_ERR_H 	= 5;

	logic		tx_ctl_char = 1;
	logic[3:0]	tx_4b_code = CTL_IDLE;

	logic		mii_tx_en_ff		= 0;
	logic		mii_tx_en_ff2		= 0;
	logic		frame_active		= 0;
	logic[3:0]	mii_txd_ff			= 0;

	always @(posedge clk_25mhz) begin

		mii_tx_en_ff			<= mii_tx_en;
		mii_tx_en_ff2			<= mii_tx_en_ff;
		mii_txd_ff				<= mii_txd;

		//Sending a frame
		if(frame_active) begin

			//Default to sending payload data
			tx_ctl_char			<= 0;
			tx_4b_code			<= mii_txd_ff;

			//If we just sent the first half of the SSD, send the second half
			if( tx_ctl_char && (tx_4b_code == CTL_SSD_J) ) begin
				tx_ctl_char		<= 1;
				tx_4b_code		<= CTL_SSD_K;
			end

			//When mii_tx_en goes low, send the first half of the end-of-stream delimiter
			if(!mii_tx_en_ff && mii_tx_en_ff2) begin
				tx_ctl_char		<= 1;
				tx_4b_code		<= CTL_END_T;
				frame_active	<= 0;
			end

			//If an error occurs, send an error character
			if(mii_tx_er) begin
				tx_ctl_char		<= 1;
				tx_4b_code		<= CTL_ERR_H;
				frame_active	<= 0;
			end

		end

		//Not sending a frame
		else begin

			//Default to sending idles
			tx_ctl_char			<= 1;
			tx_4b_code			<= CTL_IDLE;

			//When mii_tx_en goes high, send the first half of the start-of-stream delimiter
			if(mii_tx_en && !mii_tx_en_ff) begin
				frame_active	<= 1;
				tx_ctl_char		<= 1;
				tx_4b_code		<= CTL_SSD_J;
			end

			//If we just sent the first half of the ESD, send the second half
			if( tx_ctl_char && (tx_4b_code == CTL_END_T) ) begin
				tx_ctl_char		<= 1;
				tx_4b_code		<= CTL_END_R;
			end

		end

	end

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// TX 4B/5B coder

	logic[4:0] tx_5b_code;

	always_comb begin

		if(tx_ctl_char) begin

			case(tx_4b_code)
				CTL_IDLE:	tx_5b_code <= 5'b11111;
				CTL_SSD_J:	tx_5b_code <= 5'b11000;
				CTL_SSD_K:	tx_5b_code <= 5'b10001;
				CTL_END_T:	tx_5b_code <= 5'b01101;
				CTL_END_R:	tx_5b_code <= 5'b00111;
				CTL_ERR_H:	tx_5b_code <= 5'b00100;

				//send idles for unknown/invalid control chars
				default:		tx_5b_code <= 5'b11111;
			endcase

		end

		else begin
			case(tx_4b_code)
				0:	tx_5b_code <= 5'b11110;
				1:	tx_5b_code <= 5'b01001;
				2:  tx_5b_code <= 5'b10100;
				3:	tx_5b_code <= 5'b10101;
				4:	tx_5b_code <= 5'b01010;
				5:	tx_5b_code <= 5'b01011;
				6:	tx_5b_code <= 5'b01110;
				7:	tx_5b_code <= 5'b01111;
				8:	tx_5b_code <= 5'b10010;
				9:	tx_5b_code <= 5'b10011;
				10: tx_5b_code <= 5'b10110;
				11: tx_5b_code <= 5'b10111;
				12: tx_5b_code <= 5'b11010;
				13: tx_5b_code <= 5'b11011;
				14: tx_5b_code <= 5'b11100;
				15: tx_5b_code <= 5'b11101;
			endcase
		end

	end

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Sync from MII clock to TX clock domain

	logic	tx_toggle 		= 0;
	logic	tx_toggle_ff 	= 0;
	wire	tx_mii_sync		= (tx_toggle != tx_toggle_ff);

	always_ff @(posedge clk_25mhz) begin
		tx_toggle			<= !tx_toggle;
	end

	always_ff @(posedge clk_125mhz) begin
		tx_toggle_ff		<= tx_toggle;
	end

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// TX serial bitstream generator

	logic[2:0] tx_4b_bitcount	= 0;
	logic[4:0] tx_5b_code_ff	= 0;
	logic tx_unscrambled_bit	= 0;

	always_ff @(posedge clk_125mhz) begin

		//Sync to the MII clock and update when it does
		if(tx_mii_sync) begin
			tx_4b_bitcount			<= 1;
			tx_unscrambled_bit		<= tx_5b_code[4];
			tx_5b_code_ff			<= tx_5b_code;
		end

		//Nope, push out the next bit (send L-R)
		else begin
			tx_4b_bitcount				<= tx_4b_bitcount + 1'h1;
			case(tx_4b_bitcount)
				0:	tx_unscrambled_bit	<= tx_5b_code_ff[4];
				1:	tx_unscrambled_bit	<= tx_5b_code_ff[3];
				2:	tx_unscrambled_bit	<= tx_5b_code_ff[2];
				3:	tx_unscrambled_bit	<= tx_5b_code_ff[1];
				default: begin
					tx_unscrambled_bit	<= tx_5b_code_ff[0];
					tx_4b_bitcount		<= 0;
				end
			endcase
		end

	end

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// TX scrambler

	logic[10:0]	tx_lfsr = 1;

	always_ff @(posedge clk_125mhz) begin
		tx_lfsr		<= { tx_lfsr[9:0], tx_lfsr[8] ^ tx_lfsr[10] };

		data_out	<= tx_lfsr[0] ^ tx_unscrambled_bit;
	end

endmodule
