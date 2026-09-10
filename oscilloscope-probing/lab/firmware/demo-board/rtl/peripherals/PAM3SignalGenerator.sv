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
	input wire	clk_250mhz,
	input wire	clk_500mhz,

	output wire	pam3_tx_p,
	output wire	pam3_tx_n
);

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Output buffers

	wire	pam3_tx_p_out;
	wire	pam3_tx_n_out;

	wire	pam3_tx_p_tris;
	wire	pam3_tx_n_tris;

	OBUFT obuf_pam3_tx_p(
		.I(pam3_tx_p_out),
		.T(pam3_tx_p_tris),
		.O(pam3_tx_p));

	OBUFT obuf_nam3_tx_n(
		.I(pam3_tx_n_out),
		.T(pam3_tx_n_tris),
		.O(pam3_tx_n));

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Output SERDES

	logic[3:0] 	data_p	= 0;
	logic[3:0] 	data_n	= 0;

	logic[3:0]	tris_p	= 0;
	logic[3:0]	tris_n	= 0;

	OSERDESE2 #(
		.DATA_RATE_OQ("DDR"),
		.DATA_RATE_TQ("DDR"),
		.DATA_WIDTH(4),
		.SERDES_MODE("MASTER"),
		.TRISTATE_WIDTH(4)
	) oserdes_p (
		.OQ(pam3_tx_p_out),
		.OFB(),
		.TQ(pam3_tx_p_tris),
		.TFB(),
		.SHIFTOUT1(),
		.SHIFTOUT2(),
		.CLK(clk_500mhz),
		.CLKDIV(clk_250mhz),
		.D1(data_p[0]),
		.D2(data_p[1]),
		.D3(data_p[2]),
		.D4(data_p[3]),
		.D5(1'b0),
		.D6(1'b0),
		.D7(1'b0),
		.D8(1'b0),
		.TCE(1'b1),
		.OCE(1'b1),
		.TBYTEIN(),
		.TBYTEOUT(),
		.RST(1'b0),
		.SHIFTIN1(),
		.SHIFTIN2(),
		.T1(tris_p[0]),
		.T2(tris_p[1]),
		.T3(tris_p[2]),
		.T4(tris_p[3])
	);

	OSERDESE2 #(
		.DATA_RATE_OQ("DDR"),
		.DATA_RATE_TQ("DDR"),
		.DATA_WIDTH(4),
		.SERDES_MODE("MASTER"),
		.TRISTATE_WIDTH(4)
	) oserdes_n (
		.OQ(pam3_tx_n_out),
		.OFB(),
		.TQ(pam3_tx_n_tris),
		.TFB(),
		.SHIFTOUT1(),
		.SHIFTOUT2(),
		.CLK(clk_500mhz),
		.CLKDIV(clk_250mhz),
		.D1(data_n[0]),
		.D2(data_n[1]),
		.D3(data_n[2]),
		.D4(data_n[3]),
		.D5(1'b0),
		.D6(1'b0),
		.D7(1'b0),
		.D8(1'b0),
		.TCE(1'b1),
		.OCE(1'b1),
		.TBYTEIN(),
		.TBYTEOUT(),
		.RST(1'b0),
		.SHIFTIN1(),
		.SHIFTIN2(),
		.T1(tris_n[0]),
		.T2(tris_n[1]),
		.T3(tris_n[2]),
		.T4(tris_n[3])
	);

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Output symbol decoding

	typedef enum logic[1:0]
	{
		SYMBOL_MINUS_1,
		SYMBOL_0,
		SYMBOL_PLUS_1
	} symbol_t;

	symbol_t symout;
	symbol_t symout_ff;
	symbol_t symout_ff2;

	//8:1 serialization but we run the OSERDES at 4:1 to get tristates
	//so we need the data calculated twice per UI
	always_ff @(posedge clk_250mhz) begin
		symout_ff	<= symout;
		symout_ff2	<= symout_ff;

		case(symout_ff)

			//Normal logic -1
			SYMBOL_MINUS_1: begin
				tris_p <= 0;
				tris_n <= 0;

				data_p <= 4'h0;
				data_n <= 4'hf;
			end

			//Normal logic +1
			SYMBOL_PLUS_1: begin
				tris_p <= 0;
				tris_n <= 0;

				data_p <= 4'hf;
				data_n <= 4'h0;
			end

			//Tristate, or emphasis
			default: begin

				case(symout_ff2)

					//0 following a +1: drive -1 for 1/8 UI, then tristate
					SYMBOL_PLUS_1: begin
						tris_p <= 4'he;
						tris_n <= 4'he;

						data_p <= 4'h0;
						data_n <= 4'h1;
					end
					/*
					//0 following a -1: drive +1 for 1/8 UI, then tristate
					SYMBOL_MINUS_1: begin
						tris_p <= 4'he;
						tris_n <= 4'he;

						data_p <= 4'h1;
						data_n <= 4'h0;
					end*/

					//0 following a 0: just tristate
					default: begin
						tris_p <= 4'hf;
						tris_n <= 4'hf;

						data_p <= 4'h0;
						data_n <= 4'h0;
					end

				endcase

			end

		endcase

	end

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// PAM signal generation

	/*
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
	*/

	//MLT-3 repeating
	logic[1:0] count = 0;
	always_ff @(posedge clk_125mhz) begin
		count <= count + 1;

		case(count)
			0:			symout <= SYMBOL_MINUS_1;
			2:			symout <= SYMBOL_PLUS_1;
			default:	symout <= SYMBOL_0;
		endcase
	end


endmodule
