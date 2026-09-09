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

module PAM3SignalGenerator(
	input wire	clk_66mhz,
	input wire	clk_125mhz,

	output wire	pam3_tx_p,
	output wire	pam3_tx_n
);

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Output buffers

	logic	pam3_tx_p_out;
	logic	pam3_tx_n_out;

	logic	pam3_tx_p_tris;
	logic	pam3_tx_n_tris;

	OBUFT obuf_pam3_tx_p(
		.I(pam3_tx_p_out),
		.T(pam3_tx_p_tris),
		.O(pam3_tx_p));

	OBUFT obuf_nam3_tx_n(
		.I(pam3_tx_n_out),
		.T(pam3_tx_n_tris),
		.O(pam3_tx_n));

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Output symbol decoding

	typedef enum logic[1:0]
	{
		SYMBOL_MINUS_1,
		SYMBOL_0,
		SYMBOL_PLUS_1
	} symbol_t;

	symbol_t symout;

	always_comb begin

		case(symout)

			SYMBOL_MINUS_1: begin
				pam3_tx_p_tris	= 0;
				pam3_tx_n_tris	= 0;

				pam3_tx_p_out	= 0;
				pam3_tx_n_out	= 1;
			end

			SYMBOL_PLUS_1: begin
				pam3_tx_p_tris	= 0;
				pam3_tx_n_tris	= 0;

				pam3_tx_p_out	= 1;
				pam3_tx_n_out	= 0;
			end

			//zero
			default: begin
				pam3_tx_p_tris	= 1;
				pam3_tx_n_tris	= 1;

				pam3_tx_p_out	= 0;
				pam3_tx_n_out	= 0;
			end

		endcase

	end

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// PAM signal generation

	//For now just do a PRBS
	wire[1:0] prbs_out;
	PRBS31 #(
		.WIDTH(2),
		.INITIAL_SEED(1)
	) prbs (
		.clk(clk_125mhz),
		.update(1),
		.init(1'b0),
		.seed(31'h0),
		.dout(prbs_out)
	);

	always_ff @(posedge clk_125mhz) begin

		case(prbs_out)
			2'b10:		symout <= SYMBOL_MINUS_1;
			2'b11:	 	symout <= SYMBOL_PLUS_1;
			default:	symout <= SYMBOL_0;
		endcase

	end

endmodule
