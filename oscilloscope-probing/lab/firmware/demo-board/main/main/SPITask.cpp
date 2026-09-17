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
#include "SPITask.h"

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Construction / destruction

SPITask::SPITask()
	: TimerTask(0, 10 * 20)	//50 Hz update rate
	, m_spi(&FSPI, 25)		//10 MHz @ 250 MHz PCLK, not in FMC clock domain
	, m_idx(0)
{

}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

void SPITask::OnTimer()
{
	m_spi.SetCS(false);

	//pretend to read a flash
	m_spi.PrintBinary(0x03);

	//send a 24-bit address
	m_spi.PrintBinary( (m_idx >> 8) & 0xff );
	m_spi.PrintBinary( m_idx & 0xff );
	m_spi.PrintBinary( 0x00);

	//no latency for slow-read command

	//Read data
	for(int i=0; i<16; i++)
		m_spi.PrintBinary(i + (m_idx & 0x7f));

	m_spi.WaitUntilIdle();
	m_spi.SetCS(true);

	m_idx ++;
}
