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
#include "ClipMenuPage.h"

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Construction / destruction

ClipMenuPage::ClipMenuPage(MenuSystem* parent)
	: MenuPageHandler(parent)
{
	for(size_t i=0; i<4; i++)
		m_modes[i] = MODE_OFF;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Rendering

void ClipMenuPage::Render()
{
	const char* names[] =
	{
		"Off",
		"I2C",
		"UART",
		"SPI",
		"PRBS7",
		"Pulse",
		"Clock"
	};

	RenderSelector("CLIP1", 0, m_modes[0], names, 6);
	RenderSelector("CLIP2", 1, m_modes[1], names, 6);
	RenderSelector("CLIP3", 2, m_modes[2], names, 6);
	RenderSelector("CLIP4", 3, m_modes[3], names, 6);
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Event handlers

void ClipMenuPage::OnUp()
{
	if(m_activeRow > 0)
		m_activeRow --;
	else
		m_activeRow = 3;
}

void ClipMenuPage::OnDown()
{
	if(m_activeRow < 4)
		m_activeRow ++;
	else
		m_activeRow = 0;
}

void ClipMenuPage::OnLeft()
{
	EnumLeft(m_modes[m_activeRow], MODE_COUNT);
}

void ClipMenuPage::OnRight()
{
	EnumRight(m_modes[m_activeRow], MODE_COUNT);
}
