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
	APB.completer	apb,

	input wire		clk_25mhz,
	input wire		clk_66mhz,
	input wire		clk_125mhz,
	input wire		clk_250mhz,
	input wire		clk_500mhz,

	output wire		pam3_tx_p,
	output wire		pam3_tx_n
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

	//must match PAM3Mode in hwinit.h
	typedef enum logic[1:0]
	{
		MODE_OFF,
		MODE_100BASETX,
		MODE_100BASET1,			//not yet implemented
		MODE_2D_PAM3_PRBS31
	} mode_t;

	logic	mode_update	= 0;
	mode_t	mode = MODE_OFF;

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// APB interface logic

	typedef enum logic[7:0]
	{
		REG_MODE	= 0
	}
	regid_t;

	//Combinatorial readback
	always_comb begin

		apb.pready	= apb.psel && apb.penable;
		apb.prdata	= 0;
		apb.pslverr	= 0;

		if(apb.pready) begin

			//read
			if(!apb.pwrite) begin
				apb.prdata = mode;
			end

			//write
			else begin
				if( (apb.paddr != REG_MODE) ) begin
					apb.pslverr	 = 1;
				end
			end

		end
	end

	always_ff @(posedge apb.pclk or negedge apb.preset_n) begin

		//Reset
		if(!apb.preset_n) begin
			mode_update	<= 0;
			mode		<= MODE_OFF;
		end

		//Normal path
		else begin

			mode_update	<= 0;

			if(apb.pready && apb.pwrite) begin
				if(apb.paddr == REG_MODE) begin
					mode		<= mode_t'(apb.pwdata);
					mode_update	<= 1;
				end
			end

		end

	end

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Mode CDC

	mode_t mode_sync;

	RegisterSynchronizer #(
		.WIDTH($bits(mode_t)),
		.INIT(MODE_OFF),
		.IN_REG(1)
	) sync_mode(
		.clk_a(apb.pclk),
		.en_a(mode_update),
		.ack_a(),
		.reg_a(mode),

		.clk_b(clk_125mhz),
		.updated_b(),
		.reset_b(1'b0),
		.reg_b(mode_sync)
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
	// Reset the SERDES so they start in the same state

	logic[3:0] 	reset_count 	= 0;
	logic		serdes_reset	= 1;

	always_ff @(posedge clk_250mhz) begin
		if(serdes_reset) begin
			reset_count	<= reset_count + 1;
			if(reset_count == 'hf)
				serdes_reset	<= 0;
		end
	end

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
		.RST(serdes_reset),
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
		.RST(serdes_reset),
		.SHIFTIN1(),
		.SHIFTIN2(),
		.T1(tris_n[0]),
		.T2(tris_n[1]),
		.T3(tris_n[2]),
		.T4(tris_n[3])
	);

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// H-bridge control logic

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

					//0 following a -1: drive +1 for 1/8 UI, then tristate
					SYMBOL_MINUS_1: begin
						tris_p <= 4'he;
						tris_n <= 4'he;

						data_p <= 4'h1;
						data_n <= 4'h0;
					end

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
	// Ethernet frame generation

	logic		mii_tx_en	= 0;
	logic[3:0]	mii_txd		= 0;

	logic[6:0]	mii_count	= 0;

	//TODO: dont just hardcode one packet forever
	logic		mii_byte_valid	= 0;
	logic[7:0]	mii_byte		= 0;
	logic		mii_toggle		= 0;
	always_ff @(posedge clk_25mhz) begin

		//Nibble to byte deserialization
		mii_toggle	<= !mii_toggle;
		mii_tx_en	<= mii_byte_valid;
		if(!mii_toggle)
			mii_txd	<= mii_byte[3:0];
		else
			mii_txd	<= mii_byte[7:4];

		//new byte
		if(mii_toggle) begin

			mii_count		<= mii_count + 1;

			//default to sending
			mii_byte_valid	<= 1;

			case(mii_count)

				//preamble
				'h00:	mii_byte	<= 'h55;
				'h01:	mii_byte	<= 'h55;
				'h02:	mii_byte	<= 'h55;
				'h03:	mii_byte	<= 'h55;
				'h04:	mii_byte	<= 'h55;
				'h05:	mii_byte	<= 'h55;
				'h06:	mii_byte	<= 'h55;
				'h07:	mii_byte	<= 'hd5;

				//Dest MAC
				'h08:	mii_byte	<= 'h01;
				'h09:	mii_byte	<= 'h23;
				'h0a:	mii_byte	<= 'h45;
				'h0b:	mii_byte	<= 'h67;
				'h0c:	mii_byte	<= 'h89;
				'h0d:	mii_byte	<= 'hab;

				//Src MAC
				'h0e:	mii_byte	<= 'hde;
				'h0f:	mii_byte	<= 'had;
				'h10:	mii_byte	<= 'hbe;
				'h11:	mii_byte	<= 'hef;
				'h12:	mii_byte	<= 'h00;
				'h13:	mii_byte	<= 'h00;

				//Ethertype
				'h14:	mii_byte	<= 'h08;
				'h15:	mii_byte	<= 'h00;

				//Dummy payload
				'h16:	mii_byte	<= 'h00;
				'h17:	mii_byte	<= 'h11;
				'h18:	mii_byte	<= 'h22;
				'h19:	mii_byte	<= 'h33;
				'h1a:	mii_byte	<= 'h44;
				'h1b:	mii_byte	<= 'h55;
				'h1c:	mii_byte	<= 'h66;
				'h1d:	mii_byte	<= 'h77;
				'h1e:	mii_byte	<= 'h88;

				//FCS
				'h1f:	mii_byte	<= 'hf0;
				'h20:	mii_byte	<= 'h5c;
				'h21:	mii_byte	<= 'hb9;
				'h22:	mii_byte	<= 'h2e;

				//interframe gap
				default: begin
					mii_byte_valid	<= 0;
					mii_byte		<= 0;
				end

			endcase
		end

	end

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// 2D-PAM3 PRBS generation

	logic		toggle = 0;
	wire[2:0]	prbs_out;

	PRBS31 #(
		.WIDTH(3),
		.INITIAL_SEED(1)
	) prbs31 (
		.clk(clk_125mhz),
		.update(toggle),
		.init(1'b0),
		.seed(31'b0),
		.dout(prbs_out)
	);

	symbol_t prbs_symbol_i = SYMBOL_0;
	symbol_t prbs_symbol_q = SYMBOL_0;

	always_ff @(posedge clk_125mhz) begin
		toggle	<= !toggle;

		//TODO: actually use 100baseT1 symbol coding
		if(!toggle) begin

			case(prbs_out)

				3'd0: begin
					prbs_symbol_i <= SYMBOL_MINUS_1;
					prbs_symbol_q <= SYMBOL_MINUS_1;
				end

				3'd1: begin
					prbs_symbol_i <= SYMBOL_0;
					prbs_symbol_q <= SYMBOL_MINUS_1;
				end

				3'd2: begin
					prbs_symbol_i <= SYMBOL_PLUS_1;
					prbs_symbol_q <= SYMBOL_MINUS_1;
				end

				3'd3: begin
					prbs_symbol_i <= SYMBOL_MINUS_1;
					prbs_symbol_q <= SYMBOL_0;
				end

				3'd4: begin
					prbs_symbol_i <= SYMBOL_PLUS_1;
					prbs_symbol_q <= SYMBOL_0;
				end

				3'd5: begin
					prbs_symbol_i <= SYMBOL_MINUS_1;
					prbs_symbol_q <= SYMBOL_PLUS_1;
				end

				3'd6: begin
					prbs_symbol_i <= SYMBOL_0;
					prbs_symbol_q <= SYMBOL_PLUS_1;
				end

				3'd7: begin
					prbs_symbol_i <= SYMBOL_PLUS_1;
					prbs_symbol_q <= SYMBOL_PLUS_1;
				end

			endcase

		end

	end

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// PAM signal generation

	//TODO: 100baseT1 PAM3 generator

	//100baseTX MLT3 generator
	wire mlt3_out;
	BaseTXSignalGenerator basetx_siggen(
		.clk_25mhz(clk_25mhz),
		.clk_125mhz(clk_125mhz),

		//25 MHz domain
		.mii_tx_en(mii_tx_en),
		.mii_tx_er(1'b0),
		.mii_txd(mii_txd),

		.data_out(mlt3_out)
	);

	//Output line coder and mux
	logic[1:0] count = 0;
	always_ff @(posedge clk_125mhz) begin

		case(mode_sync)

			//MLT-3 encoder
			MODE_100BASETX: begin
				if(mlt3_out)
					count <= count + 1;

				case(count)
					0:			symout <= SYMBOL_MINUS_1;
					2:			symout <= SYMBOL_PLUS_1;
					default:	symout <= SYMBOL_0;
				endcase
			end	//MODE_100BASETX

			//TODO
			MODE_100BASET1: begin
				symout	<= SYMBOL_0;
			end

			//PAM3 PRBS
			MODE_2D_PAM3_PRBS31: begin
				if(toggle)
					symout	<= prbs_symbol_i;
				else
					symout	<= prbs_symbol_q;
			end

			//Nothing to do
			MODE_OFF: begin
				symout	<= SYMBOL_0;
			end

			default: begin
				symout	<= SYMBOL_0;
			end

		endcase
	end


endmodule
