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
#include "RGBTask.h"

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Construction / destruction

RGBTask::RGBTask()
	: TimerTask(0, 10 * 100)	//10 Hz refresh rate
	, m_pattern(PATTERN_OFF)
	, m_step(0)
	, m_lastWasOff(true)
{
	ClearFramebuffer();
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

void RGBTask::OnTimer()
{
	static uint32_t color_rgbw[] =
	{
		0x200000,
		0x002000,
		0x000020,
		0x202020
	};

	switch(m_pattern)
	{
		case PATTERN_GREEN_CHASE:
			ClearFramebuffer();
			m_step = (m_step + 1) % 16;
			m_framebuffer[m_step / 4] = 0x002000;
			break;

		case PATTERN_PINGPONG:
			{
				ClearFramebuffer();

				m_step ++;

				//Every 2 steps, change position
				uint32_t tick = m_step;
				uint32_t pos = tick & 3;

				//Invert position alternate steps so we pingpong
				if(tick & 4)
					pos = (3 - pos);

				//Next bits select color
				uint32_t coloridx = (tick >> 2) & 3;
				m_framebuffer[pos] = color_rgbw[coloridx];
			}
			break;

		case PATTERN_OFF:
		default:
			if(m_lastWasOff)
				return;

			m_lastWasOff = true;
			ClearFramebuffer();
			break;
	}

	if(m_pattern != PATTERN_OFF)
		m_lastWasOff = false;

	//Push it
	for(uint32_t i=0; i<4; i++)
		FRGBLED.framebuffer[i] = m_framebuffer[i];
}
