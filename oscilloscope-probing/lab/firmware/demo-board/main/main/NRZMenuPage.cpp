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
#include "NRZMenuPage.h"

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Construction / destruction

NRZMenuPage::NRZMenuPage(MenuSystem* parent, volatile APB_NRZSignalGenerator* gen)
	: MenuPageHandler(parent)
	, m_gen(gen)
{
	for(size_t i=0; i<4; i++)
		m_muxsel[i] = NRZMode::Off;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Rendering

void NRZMenuPage::Render()
{
	RenderSelector("OUT1", 0, m_muxsel[0], g_nrzmodeNames, 6);
	RenderSelector("OUT2", 1, m_muxsel[1], g_nrzmodeNames, 6);
	RenderSelector("OUT3", 2, m_muxsel[2], g_nrzmodeNames, 6);
	RenderSelector("OUT4", 3, m_muxsel[3], g_nrzmodeNames, 6);
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Event handlers

void NRZMenuPage::OnUp()
{
	if(m_activeRow > 0)
		m_activeRow --;
	else
		m_activeRow = 3;
}

void NRZMenuPage::OnDown()
{
	if(m_activeRow < 4)
		m_activeRow ++;
	else
		m_activeRow = 0;
}

void NRZMenuPage::OnLeft()
{
	EnumLeft(m_muxsel[m_activeRow], NRZMode::Count);
	UpdateFPGA();
}

void NRZMenuPage::OnRight()
{
	EnumRight(m_muxsel[m_activeRow], NRZMode::Count);
	UpdateFPGA();
}

void NRZMenuPage::UpdateFPGA()
{
	for(size_t i=0; i<4; i++)
		m_gen->MUXSEL[i] = static_cast<uint32_t>(m_muxsel[i]);
}
