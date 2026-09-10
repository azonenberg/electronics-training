/***********************************************************************************************************************
*                                                                                                                      *
* electronics-training                                                                                                 *
*                                                                                                                      *
* Copyright (c) 2023-2026 Andrew D. Zonenberg and contributors                                                         *
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

#include "demo.h"
#include "MenuSystem.h"
#include "AboutMenuPage.h"

void AboutMenuPage::Render()
{
	//FPGA ID
	uint32_t idcode = FDEVINFO.idcode;
	Printf("FPGA: %s rev %u\n", GetNameOfFPGA(idcode), static_cast<unsigned int>(idcode >> 28));

	//Bitstream info
	//Format FPGA firmware string based on the usercode (see XAPP1232)
	//TODO: refactor this into a function we can use elsewhere
	int day = g_usercode >> 27;
	int mon = (g_usercode >> 23) & 0xf;
	int yr = 2000 + ((g_usercode >> 17) & 0x3f);
	int hr = (g_usercode >> 12) & 0x1f;
	int min = (g_usercode >> 6) & 0x3f;
	int sec = g_usercode & 0x3f;
	static const char* months[16] =
	{
		"",		//months in usercode use 1-based indexing
		"Jan",
		"Feb",
		"Mar",
		"Apr",
		"May",
		"Jun",
		"Jul",
		"Aug",
		"Sep",
		"Oct",
		"Nov",
		"Dec",
		"",
		"",
		""
	};
	Printf("      %s %2d %04d %02d%02d%02d\n", months[mon], day, yr, hr, min, sec);

	//MCU hardware
	Printf("MCU : STM32%s\n", GetPartName(DBGMCU.IDCODE & 0xfff));
	Printf("      stepping %s\n", GetStepping(DBGMCU.IDCODE >> 16));

	//Firmware date / time
	static const char* buildtime = __TIME__;
	Printf("      %s %c%c%c%c%c%c\n",
		__DATE__, buildtime[0], buildtime[1], buildtime[3], buildtime[4], buildtime[6], buildtime[7]);

	//For now, hard code PCB rev since there's no revision straps defined yet
	Printf("PCB : rev 0.1");
}
