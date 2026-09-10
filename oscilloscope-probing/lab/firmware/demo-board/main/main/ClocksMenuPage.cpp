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
#include "ClocksMenuPage.h"

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Construction / destruction

ClocksMenuPage::ClocksMenuPage(MenuSystem* parent)
	: MenuPageHandler(parent)
{
	/*
	for(size_t i=0; i<4; i++)
		m_modes[i] = MODE_OFF;*/
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Rendering

void ClocksMenuPage::Render()
{
	/*
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

	for(uint32_t i=0; i<4; i++)
	{
		bool active = IsRowActive(i);
		Printf("CLIP%u:  %c %6s %c\n",
			static_cast<unsigned int>(i) + 1,
			active ? '<' : ' ',
			names[m_modes[i]],
			active ? '>' : ' ');
	}
	*/
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Event handlers

void ClocksMenuPage::OnUp()
{
	/*
	if(m_activeRow > 0)
		m_activeRow --;
	else
		m_activeRow = 3;*/
}

void ClocksMenuPage::OnDown()
{
	/*
	if(m_activeRow < 4)
		m_activeRow ++;
	else
		m_activeRow = 0;*/
}

void ClocksMenuPage::OnLeft()
{
	/*
	if(m_modes[m_activeRow] > 0)
		m_modes[m_activeRow] = static_cast<ClocksMode>(m_modes[m_activeRow] - 1);
	else
		m_modes[m_activeRow] = static_cast<ClocksMode>(MODE_COUNT - 1);*/
}

void ClocksMenuPage::OnRight()
{
	/*
	if(m_modes[m_activeRow] < (MODE_COUNT - 1))
		m_modes[m_activeRow] = static_cast<ClocksMode>(m_modes[m_activeRow] + 1);
	else
		m_modes[m_activeRow] = static_cast<ClocksMode>(0);*/
}
