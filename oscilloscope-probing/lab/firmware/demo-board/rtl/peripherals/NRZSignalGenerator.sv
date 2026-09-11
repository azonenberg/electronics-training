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

module NRZSignalGenerator(
	APB.completer		apb,

	output logic[3:0]	dout
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
	// APB interface registers

	//must match NRZMode in hwinit.h
	typedef enum logic[3:0]
	{
		MODE_OFF,
		MODE_I2C,
		MODE_UART,
		MODE_SPI,
		MODE_PRBS7,
		MODE_PRBS31,
		MODE_PULSE,
		MODE_CLOCK
	} mode_t;

	mode_t modesel[4];

	initial begin
		for(integer i=0; i<4; i++)
			modesel[i] = MODE_OFF;
	end

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// APB interface logic

	//Combinatorial readback
	always_comb begin

		apb.pready	= apb.psel && apb.penable;
		apb.prdata	= 0;
		apb.pslverr	= 0;

		if(apb.pready) begin

			//read
			if(!apb.pwrite) begin
				apb.prdata = modesel[apb.paddr[3:2]];
			end

			//write
			else begin
				if( (apb.paddr != 'h0) && (apb.paddr != 'h4) && (apb.paddr != 'h8) && (apb.paddr != 'hc) ) begin
					apb.pslverr	 = 1;
				end
			end

		end
	end

	always_ff @(posedge apb.pclk or negedge apb.preset_n) begin

		//Reset
		if(!apb.preset_n) begin
			for(integer i=0; i<4; i++)
				modesel[i] = MODE_OFF;
		end

		//Normal path
		else begin

			if(apb.pready && apb.pwrite) begin
				modesel[apb.paddr[3:2]]	<= mode_t'(apb.pwdata);
			end

		end

	end

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// PRBS generators

	wire	prbs7_out;
	wire	prbs31_out;

	PRBS7 #(
		.WIDTH(1),
		.INITIAL_SEED(1)
	) prbs7 (
		.clk(apb.pclk),
		.update(1'b1),
		.init(1'b0),
		.seed(7'b0),
		.dout(prbs7_out)
	);

	PRBS31 #(
		.WIDTH(1),
		.INITIAL_SEED(1)
	) prbs31 (
		.clk(apb.pclk),
		.update(1'b1),
		.init(1'b0),
		.seed(31'b0),
		.dout(prbs31_out)
	);

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Clock generator (half rate)

	logic toggle = 0;

	always_ff @(posedge apb.pclk) begin
		toggle	<= !toggle;
	end

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Output muxing

	/*
	MODE_I2C,
	MODE_UART,
	MODE_SPI,
	MODE_PULSE,
	*/

	//Combinatorial mux input configuration
	logic[7:0]	dout3_in;
	logic[7:0]	dout2_in;
	logic[7:0]	dout1_in;
	logic[7:0]	dout0_in;

	always_comb begin

		//Default everything to off
		dout3_in	= 0;
		dout2_in	= 0;
		dout1_in	= 0;
		dout0_in	= 0;

		//MODE_OFF is just zero nothing needed there

		//PRBS7
		dout3_in[MODE_PRBS7]	= prbs7_out;
		dout2_in[MODE_PRBS7]	= prbs7_out;
		dout1_in[MODE_PRBS7]	= prbs7_out;
		dout0_in[MODE_PRBS7]	= prbs7_out;

		//PRBS31
		dout3_in[MODE_PRBS31]	= prbs31_out;
		dout2_in[MODE_PRBS31]	= prbs31_out;
		dout1_in[MODE_PRBS31]	= prbs31_out;
		dout0_in[MODE_PRBS31]	= prbs31_out;

		//CLOCK
		dout3_in[MODE_CLOCK]	= toggle;
		dout2_in[MODE_CLOCK]	= toggle;
		dout1_in[MODE_CLOCK]	= toggle;
		dout0_in[MODE_CLOCK]	= toggle;

	end

	//Registered muxes since all pattern generators use the same clock
	always_ff @(posedge apb.pclk) begin
		dout[0]		<= dout0_in[modesel[0]];
		dout[1]		<= dout1_in[modesel[1]];
		dout[2]		<= dout2_in[modesel[2]];
		dout[3]		<= dout3_in[modesel[3]];
	end

endmodule
