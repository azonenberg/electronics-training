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
	@brief Top level bus interconnect
 */
module APBInterconnect(

	//Main system APB in
	APB.completer 		apb_fmc,

	//APB1 (0xc000_0000, 1 kB per peripheral)
	APB.requester		apb1,

	//APB2 (0xc001_0000, 4 kB per peripheral)
	APB.requester		apb2,

	//Debug APB in
	APB.completer 		apb_debug

	//Small debug APB TODO
);

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Main system top level bus bridge (0xc000_0000)

	//Optional register slice for timing
	APB #(.DATA_WIDTH(32), .ADDR_WIDTH(24), .USER_WIDTH(0)) apb_fmc_pipe();
	APBRegisterSlice #(.DOWN_REG(0), .UP_REG(0)) regslice_apb_fmc(
		.upstream(apb_fmc),
		.downstream(apb_fmc_pipe));

	//Root bridge: 64K per block
	APB #(.DATA_WIDTH(32), .ADDR_WIDTH(16), .USER_WIDTH(0)) apb_fmc_root[1:0]();
	APBBridge #(
		.BASE_ADDR(32'h0000_0000),
		.BLOCK_SIZE(32'h1_0000),
		.NUM_PORTS(2)
	) root_bridge (
		.upstream(apb_fmc_pipe),
		.downstream(apb_fmc_root)
	);

	//Optional register slices for downstream logic
	APBRegisterSlice #(.DOWN_REG(0), .UP_REG(0)) regslice_apb1(
		.upstream(apb_fmc_root[0]),
		.downstream(apb1));

	APBRegisterSlice #(.DOWN_REG(0), .UP_REG(0)) regslice_apb2(
		.upstream(apb_fmc_root[1]),
		.downstream(apb2));

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Debug top level bus bridge (0x4000_0000, 1 MB blocks)

	localparam NUM_APB_L1 = 2;
	APB #(.ADDR_WIDTH(20), .DATA_WIDTH(32), .USER_WIDTH(0)) apb_debug_root[NUM_APB_L1-1:0]();

	//Root bridge
	APBBridge #(
		.BASE_ADDR(32'h4000_0000),
		.BLOCK_SIZE(32'h10_0000),
		.NUM_PORTS(NUM_APB_L1)
	) debug_root_bridge (
		.upstream(apb_debug),
		.downstream(apb_debug_root)
	);

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Debug ROM table (0x4000_0000)

	APB #(.ADDR_WIDTH(20), .DATA_WIDTH(32), .USER_WIDTH(0)) apb_debug_rom();

	APBRegisterSlice #(.DOWN_REG(0), .UP_REG(0)) regslice_apb_debug_rom(
		.upstream(apb_debug_root[0]),
		.downstream(apb_debug_rom));

	DebugROM #(
		//.DEVICE_0_TYPE("ILA_"),
		//.DEVICE_0_ADDR(32'h4000_0800),
	) debugrom (
		.apb(apb_debug_rom)
	);

endmodule
